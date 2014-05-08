#!/usr/bin/perl -w
use strict;

my $new_dir = shift or die "Usage: <new_dirname>\n";
if(-d $new_dir) {
	die "$new_dir is already taken.\n";
}

`mkdir $new_dir`;

my %done = ();

# 2013-2351_130909_SN484_0214_BD2AUKACXX_8_1_sequence.txt.gz.clip.fq.gz
my @files = `find -iname "*sequence.txt.gz.clip.fq.gz"`;
foreach my $file (@files) {
	chomp $file;
	if($file =~ /\/(\d{4}-\d+_.*\.gz)\.clip\.fq\.gz/) {
		$done{$1} = 1;
	}
}

my %raw = ();

my @fastq = `find /glusterfs/users/JGRUNDSTAD/bionimbus/FO_NBCP -iname "*.gz"`;
foreach my $raw (@fastq) {
	chomp $raw;
	if($raw =~ /\/(\d{4}-\d+_.*_[1-8]_[12]_sequence\.txt\.gz)/) {
		my $seq_file = $1;
		if(!defined $done{$seq_file}) {
			print STDERR "$seq_file\n";
			`ln -s /glusterfs/users/JGRUNDSTAD/bionimbus/FO_NBCP/$seq_file $new_dir/$seq_file`;
		}
	}
}
