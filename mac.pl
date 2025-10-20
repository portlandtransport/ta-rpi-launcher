my $rec = `/sbin/ifconfig -a | grep "ether"`;
my ($field1, $field2, $mac) = split(/\s+/, $rec);

$mac = uc($mac);

$revision = `grep '^Revision' /proc/cpuinfo | cut -f2 -d':'`;
$revision =~ s/\s+//g;

my $starttime = time()*1000;
my $osid = "MAC:".$mac.":OS";

my $release = "R7.0.1";

my $proposed_js = <<EOD
// Overwrite this with actual HW ID
//hwid = 'MAC ADDRESS'
hwid = '$mac';
pirev = '$revision';
trrelease = '$release';
EOD
;

unlink("/tmp/hwid.js");

open(OUT,">/tmp/hwid.js");
print OUT $proposed_js;
close(OUT);

unlink("/tmp/osinfo.json");

open(OUT,">:utf8","/tmp/osinfo.json");
print OUT <<EOD
{
	"start_time": $starttime,
	"id": "$osid",
	"platform": "$revision-$release"	
}
EOD
;
close(OUT);


print $mac;
exit(0); 
