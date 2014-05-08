#!/usr/bin/perl -w
use strict;
$|=1;
my $bam = shift;
my $tmp_sam = "$bam.sam.tmptagged";
print STDERR "get stub ... ";
my @stub_ar = split /\./, $bam;
my $stub = $stub_ar[0];
my $id = '';
if($stub =~ /(\d+-\d+)_/) {
	$id = $1;
}
print "$stub\n";
print "get header ... ";
my $header = `samtools view -H $bam`;
print "done\nadd header to tmp_sam ... ";
`echo "$header\@RG	ID\:$stub	SM\:$id	LB\:$id	PL\:illumina" > $tmp_sam`;
print "done\nawk call ...\n";
`samtools view $bam | awk '{ print \$0 "	RG:Z:$stub" }' >> $tmp_sam`;
#while(my $line = `samtools view $bam`) {
#	chomp $line;
#	print TMP_SAM "$line	RG:Z:$stub\n";
#}
`rm $bam`;
`samtools view -Sb $bam.sam.tmptagged > $bam`;
`rm $bam.sam.tmptagged`;

