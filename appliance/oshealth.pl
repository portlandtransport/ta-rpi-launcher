#!/usr/bin/perl

use strict;

use LWP::UserAgent;
use JSON;
use Data::Dumper;

my $rec = `/sbin/ifconfig -a | grep "HWaddr"`;
my ($field1, $field2, $field3, $field4, $mac) = split(/\s+/, $rec);

$mac = uc($mac);

# get uptime from /proc/uptime
open(IN,"</proc/uptime");
my $up_string = <IN>;
close(IN);
my ($up) = split(/\s/,$up_string); # gets us fractional seconds
my $boot = time() - $up;
# round to nearest 10 seconds to avoid minor variations
$boot = int(($boot+5)/10)*10;

my $ua = LWP::UserAgent->new();

if (open(IN,"<:utf8","/tmp/osinfo.json")) {
	my $json = "";
	while (my $line =  <IN>) {
		$json .= $line;
	}
	close(IN);
	
	my $content = from_json($json);
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
	
	sleep(int(rand(1700)));
	my $response = $ua->post("https://ta-web-services.com/cron/".$content->{'id'}."/health_update",Content => $content);
	
	if ($response->code eq '200') {
		my $reset = from_json($response->content);
		if ($reset->{'reset'}) {
			`/sbin/reboot`;
		}
	}

}


exit(0);

#data: { timestamp: arrivals_object.start_time, start_time: arrivals_object.start_time, version: arrivals_object.version, id: arrivals_object.id, application_id: arrivals_object.input_params.applicationId, application_name: arrivals_object.input_params.applicationName, application_version: arrivals_object.input_params.applicationVersion, "height": jQuery(window).height(), "width": jQuery(window).width(), "platform": platform }
							
