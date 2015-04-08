#!/usr/bin/perl -w
use strict;
my $count = 1;
while(<>) {
	my $line = $_;
	if($count % 4 == 0) {
		
		# illumina to sanger
		$line =~ tr/@-hi-z/!-II/;
		
		# sanger to illumina
		#$line =~ tr/!-IJ-Z/@-hh/; # anything J to Z change to h
	}
	print $line;
	$count++;
}
