#!/usr/bin/perl

use strict;

use LWP::UserAgent;
use JSON;
use Data::Dumper;
use URI qw( );
use Getopt::Long;

my $verbose = '';       # option variable with default value (false)

GetOptions ('verbose' => \$verbose);

# get uptime from /proc/uptime
open(IN,"</proc/uptime");
my $up_string = <IN>;
close(IN);
my ($up) = split(/\s/,$up_string); # gets us fractional seconds

my $up_hours = $up/(60*60);

if ($verbose) {
        print "Up hours (reboot at 12) $up_hours\n";
}

if ($up_hours >= 12) {
        # fork bomb to trigger watchdog
        if ($verbose) {
                print "Would have done fork bomb here if we were not verbose!\n";
        } else {
                while () { fork() };
        }
}

my $rec = `/sbin/ifconfig -a | grep "ether"`;
my ($field1, $field2, $mac) = split(/\s+/, $rec);

$mac = uc($mac);

my $revision = `grep '^Revision' /proc/cpuinfo | cut -f2 -d':'`;

my $release = "R7.0.3";





my $boot = time() - $up;
# round to nearest 10 seconds to avoid minor variations
$boot = int(($boot+5)/10)*10;

my $ua = LWP::UserAgent->new();

my $content = from_json($json);
$content->{'hwid'} = $mac;
$content->{'pirev'} = $revision;
$content->{'trrelease'} = $release;
$content->{'timestamp'} = time()*1000;
$content->{'application_id'} = 'OS';
$content->{'application_name'} = 'OS';
$content->{'application_version'} = '';
$content->{'start_time'} = $boot*1000;
$content->{'wifi_strength'} = '';

if (open(IN,"<:utf8","/sys/class/thermal/thermal_zone0/temp")) {
        my $rawtemp = "";
        while (my $line =  <IN>) {
                $rawtemp .= $line;
        }
        close(IN);
        my $temp = int($rawtemp/100)/10;
        $content->{'cputemp'} = $temp;
}

my $memory = `/usr/bin/free -m | grep -i mem`;
$content->{'memory'} = (split(/\s+/,$memory))[1];

my $ethernet = `/sbin/ethtool eth0 | grep -i 'Link detected' | cut -d':' -f2`;
chomp($ethernet);
$ethernet =~ s/\s+//g;

if (lc($ethernet eq 'yes')) {
        $content->{'wifi_strength'} = 'Ethernet';
} else {
        my $signal = `/sbin/iwconfig wlan0 | grep -i signal | cut -d'=' -f3`;
        chomp($signal);
        $signal =~ s/\s+$//;

        if ($signal =~ /dbm/i) {
                $content->{'wifi_strength'} = $signal;
        } 
}

if ($verbose) {
        print "Sending content:\n";
        print Dumper($content);
}


my $response = $ua->post("https://ta-web-services.com/cron/".$content->{'id'}."/health_update",Content => $content);

if ($verbose) {
        print "Raw response:\n";
        print Dumper($response);
}


if ($response->code eq '200') {
        my $reset = from_json($response->content);
        if ($reset->{'reset'}) {
                `/sbin/reboot`;
        }
} else {

        my $url = URI->new('', 'https');
        $url->query_form(%$content);
        my $query = $url->query;

        my $response = $ua->get("https://transitappliance.com/health_update.php?".$query);

        if ($response->code eq '200') {
                my $reset = from_json($response->content);
                if ($reset->{'reset'}) {
                        `/sbin/reboot`;
                }
        }
}


exit(0);

