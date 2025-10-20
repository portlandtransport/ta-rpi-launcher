#!/usr/bin/perl

use IO::Socket::INET;

if (&connected) {
	# see if chromium is running

	$chromium_count = `ps -A | grep chrom | wc -l`;
	if ($chromium_count > 4) {
		#print "Chrome running\n";
	} else {
		print "Chrome NOT running\n";
		system("/sbin/shutdown -r now");
	}
	exit(0);
} else {
	print "reboot here...\n";
	system("/sbin/shutdown -r now");
}


sub connected {
	
	for (0..9) {

		my @sites = (
			"www.google.com",
			"www.yahoo.com",
			"www.microsoft.com",
			"www.twitter.com"
		);
		
		for my $site (@sites) {
		  my $handle = IO::Socket::INET->new('PeerAddr'=>$site.":80",'Timeout'=>10, 'Proto'=> 'tcp');
		
		  if (defined $handle && $handle) {
		    $handle->close();
		    return 1;
		  }
		}
		
		sleep(10);
	}
		
	return 0;
}
