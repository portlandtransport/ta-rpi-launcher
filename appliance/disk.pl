open(IN,"<:utf8","/proc/mounts");
while (my $line = <IN>) {
	if ($line =~ /root/) {
		if ($line =~ /rw/) {
			print "Read-Write\n";
		} else {
			print "Read-Only\n";
		}
	}
}
close(IN);
exit(0); 
