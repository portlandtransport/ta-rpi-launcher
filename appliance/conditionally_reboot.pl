#!/usr/bin/perl

if (open(IN,"</proc/uptime")) {
	my $line = <IN>;
	close(IN);
	my ($seconds) = split(/\s+/,$line);
	my $hours = int($seconds/3600);
	print "$hours\n";
	if ($hours > 23) {
		system("sudo reboot");
	}
} else {
	print "Could not open /proc/uptime\n";
	exit(0);
}
