#!/usr/bin/perl -w
use strict;
use warnings;
BEGIN{push @INC, '/glusterfs/users/JGRUNDSTAD/cancerseq_scripts/'};
use SubmitterBot;
$|=1;
# Very basic wrapper script to run BWA on fastq files in a directory
# Several parameters are often changed run to run
if($#ARGV < 2) {
	print "Usage: <unique_job_name_no_spaces> <# nodes to occupy> <list of #1 end input files (*_1_sequence.txt.gz)>\n";
	exit;
}

my $job_name = shift;
my $max_nodes = shift;
my @FILES = @ARGV[0..$#ARGV];


foreach my $fi (@FILES) {
	print "$fi\n";
}

my $fastx= "fastx_quality_stats";
my $bwa= "/usr/local/SwiftSeq/bwa-0.5.9/bwa";
my $samtools= "/usr/local/SwiftSeq/samtools-0.1.18/samtools";
my $bedtools= "/usr/local/SwiftSeq/BEDTools-Version-2.16.2/bin";
my $picard= "/usr/local/SwiftSeq/picard-tools-1.74/";
my $picard_temp = "picard_temp";
my $seqprep= "/usr/local/SwiftSeq/jstjohn-SeqPrep-b83fd00/SeqPrep";
my $ref_fa= "/glusterfs/users/JGRUNDSTAD/REF/hg19/hg19_Ordered.fa";
my $refseq_bed= "/glusterfs/users/JGRUNDSTAD/REF/hg19/hg19_Ordered.bed";
my $maxMem= 2000000000;

my $i = 1;
my $PBS_O_WORKDIR = `pwd`;
chomp $PBS_O_WORKDIR;


if(!-e "qsub_logs") {
	`mkdir qsub_logs`;
}
`mkdir -p scripts`;

my $bwa_qsub_args = " -N $job_name -l nodes=1:ppn=8 -j oe -o qsub_logs/";
my $samtools_qsub_args = " -N $job_name -l nodes=1:ppn=1 -j oe -o qsub_logs/";
my $samtools2_qsub_args = " -N $job_name -l nodes=1:ppn=2 -j oe -o qsub_logs/";

my $j  = 1; # script counter

my $bot = new SubmitterBot;
$bot->job_name($job_name);

my %SAMPLES = ();


# Get the quality scores
my @qs_cmds = ();
foreach my $sample (@FILES) { # e.g. 2011-1502_111228_SN673_0122_AC028YACXX_1_1_sequence.txt.gz
	if($sample =~ /^(\S+)_1_sequence\.txt\.gz/) { # get the stub
		$sample = $1;
	}
        
	my $f1 = $sample . "_1_sequence.txt.gz";
	my $f2 = $sample . "_2_sequence.txt.gz";
	$SAMPLES{$sample}{f1} = $f1;
	$SAMPLES{$sample}{f2} = $f2;

    
    # Run fastq_stats
    #print POOL "gzip -dc $f1 | $fastx -N -o $f1.qs\n";
    #print POOL "gzip -dc $f2 | $fastx -N -o $f2.qs\n";
	my $script = "scripts/$j.qs.$i.sh";
	$i++;
	my $script2 = "scripts/$j.qs.$i.sh";
	$i++;


	`echo \"hostname\ncd $PBS_O_WORKDIR\" > $script`;
	`echo \"hostname\ncd $PBS_O_WORKDIR\" > $script2`;
    `echo \"gzip -dc $f1 | $fastx -N -o $f1.qs\" >> $script`;
    `echo \"gzip -dc $f2 | $fastx -N -o $f2.qs\" >> $script2`;
	my $cmd = "qsub $samtools2_qsub_args $script";
	my $cmd2 = "qsub $samtools2_qsub_args $script2";
	push @qs_cmds, $cmd;
	push @qs_cmds, $cmd2;
    
}
$j++;
$bot->batch('qs');
$bot->max_jobs($max_nodes * 4);
$bot->jobs(\@qs_cmds);
$bot->submit_jobs();


# Clip the reads
my @seqprep_cmds = ();
$i = 1;
foreach my $sample (keys %SAMPLES) {
    # Run seqprep
	my $f1 = $SAMPLES{$sample}{f1};
	my $f2 = $SAMPLES{$sample}{f2};
	#print "File1: $f1\nFile2: $f2\n";
	my $script = "scripts/$j.seqprep.$i.sh";
	$i++;
    `echo \"hostname\ncd $PBS_O_WORKDIR\n$seqprep -6 -f $f1 -r $f2 -1 $f1.clip.fq.gz -2 $f2.clip.fq.gz -s $sample.me.fq.gz > $sample.sp.log 2>&1\" > $script`;
	my $seqprep_cmd = "qsub $samtools_qsub_args $script";
	push @seqprep_cmds, $seqprep_cmd;
}
$j++;
$bot->batch('seqprep');
$bot->max_jobs($max_nodes * 8);
$bot->jobs(\@seqprep_cmds);
$bot->submit_jobs();


# Index the paired end reads
my @bwa_cmds = ();
$i = 0;
foreach my $sample (keys %SAMPLES) {
    foreach my $file ($SAMPLES{$sample}{f1}, $SAMPLES{$sample}{f2}) {
		$i++;
		my $script = "scripts/$j.bwa.$i.sh";
		`echo \"hostname\ncd $PBS_O_WORKDIR\n\" > $script`;

		# Foreach sequence end Run bwa aln on clipped reads
		`echo \"$bwa aln -q 15 -t 8 -f $file.clip.sai $ref_fa $file.clip.fq.gz > $sample.aln.$i.log 2>&1\" >> $script`;
		my $bwa_cmd = "qsub $bwa_qsub_args $script";
		push @bwa_cmds, $bwa_cmd;
    }
}
$j++;
$bot->batch('index_clipped');
$bot->max_jobs($max_nodes);
$bot->jobs(\@bwa_cmds);
$bot->submit_jobs();


# Align the paired reads
my @align_cmds = ();
$i = 1;
foreach my $sample (keys %SAMPLES) {
	my $f1 = $SAMPLES{$sample}{f1};
	my $f2 = $SAMPLES{$sample}{f2};

	my $script = "scripts/$j.alignpe.$i.sh";
	$i++;
    # Pair bwa alignments, convert to BAM, throw out unaligned reads, sort output by coords
    `echo \"hostname\ncd $PBS_O_WORKDIR\n($bwa sampe -o 100 $ref_fa $f1.clip.sai $f2.clip.sai $f1.clip.fq.gz $f2.clip.fq.gz | $samtools view -bT $ref_fa - > $sample.clip.bam ) > $sample.sampe.log 2>&1\" > $script`;
	push @align_cmds, "qsub $bwa_qsub_args $script";
}
$j++;
$bot->batch('align_pe');
$bot->max_jobs($max_nodes);
$bot->jobs(\@align_cmds);
$bot->submit_jobs();


# rmdups
my @rmdup_cmds = ();
$i = 1;
foreach my $sample (keys %SAMPLES) {
	my $script = "scripts/$j.rmdup.$i.sh";
	$i++;
	#`echo \"hostname\ncd $PBS_O_WORKDIR\n$samtools sort -m $maxMem $sample.clip.bam $sample.clip.srt > $sample.sampe.srt.log 2>&1\" > $script`;
	`echo \"hostname\ncd $PBS_O_WORKDIR\njava -Xmx8g -jar $picard/SortSam.jar TMP_DIR=$picard_temp INPUT=$sample.clip.bam OUTPUT=$sample.clip.srt.bam SORT_ORDER=coordinate VALIDATION_STRINGENCY=LENIENT > $sample.clip.srt.bam.log 2>&1\" > $script`;
    
    # Mark duplicates
	#`echo \"$samtools rmdup $sample.clip.srt.bam $sample.clip.rmdup.srt.bam > $sample.clip.rmdup.log 2>&1\" >> $script`;
	`echo \"java -Xmx8g -jar $picard/MarkDuplicates.jar TMP_DIR=$picard_temp REMOVE_DUPLICATES=true ASSUME_SORTED=true MAX_FILE_HANDLES_FOR_READ_ENDS_MAP=500 INPUT=$sample.clip.srt.bam OUTPUT=$sample.clip.rmdup.srt.bam METRICS_FILE=$sample.clip.rmdup.srt.metrics VALIDATION_STRINGENCY=LENIENT > $sample.clip.rmdup.srt.bam.log 2>&1  \" >> $script`;
	push @rmdup_cmds, "qsub $bwa_qsub_args $script";
}
$j++;
$bot->batch('sort_rmdup-clip');
$bot->max_jobs($max_nodes);
$bot->jobs(\@rmdup_cmds);
$bot->submit_jobs();


# align the merged file
my @bwa_me_cmds = ();
$i = 1;
foreach my $sample (keys %SAMPLES) {
	my $script = "scripts/$j.bwa.me.$i.sh";
	$i++;
	#Run Bwa on merged sequence file
    `echo \"hostname\ncd $PBS_O_WORKDIR\n($bwa aln -q 15 -t 8 $ref_fa $sample.me.fq.gz | $bwa samse -n 10 $ref_fa - $sample.me.fq.gz | $samtools view -bT $ref_fa - > $sample.me.bam) > $sample.samse.log 2>&1\" > $script`;
	push @bwa_me_cmds, "qsub $bwa_qsub_args $script";
}
$j++;
$bot->batch('align_merged');
$bot->max_jobs($max_nodes);
$bot->jobs(\@bwa_me_cmds);
$bot->submit_jobs();


# sort the merged bam
my @samtools_cmds = ();
$i = 1;
foreach my $sample (keys %SAMPLES) {

	my $script = "scripts/$j.samtools.$i.sh";
	$i++;
	#`echo \"hostname\ncd $PBS_O_WORKDIR\n$samtools sort -m $maxMem $sample.me.bam $sample.me.srt > $sample.samse.srt.log 2>&1\" > $script`;
	`echo \"hostname\ncd $PBS_O_WORKDIR\njava -Xmx8g -jar $picard/SortSam.jar TMP_DIR=$picard_temp INPUT=$sample.me.bam OUTPUT=$sample.me.srt.bam SORT_ORDER=coordinate VALIDATION_STRINGENCY=LENIENT > $sample.me.srt.bam.log 2>&1\" > $script`;
	push @samtools_cmds, "qsub $bwa_qsub_args $script";
}
$j++;
$bot->batch('sorting_me.bam');
$bot->max_jobs($max_nodes);
$bot->jobs(\@samtools_cmds);
$bot->submit_jobs();



# final rmdup, merge, flagstat and coverage generation
@samtools_cmds = ();
$i = 1;
foreach my $sample (keys %SAMPLES) {
	
	my $script = "scripts/$j.final_samtools.$i.sh";
	$i++;

    # Mark duplicates
	#`echo \"hostname\ncd $PBS_O_WORKDIR\n$samtools rmdup -s $sample.me.srt.bam $sample.me.rmdup.srt.bam > $sample.me.rmdup.log 2>&1\" > $script`;

	`echo \"hostname\ncd $PBS_O_WORKDIR\njava -Xmx2g -jar $picard/MarkDuplicates.jar TMP_DIR=$picard_temp REMOVE_DUPLICATES=true ASSUME_SORTED=true MAX_FILE_HANDLES_FOR_READ_ENDS_MAP=500 INPUT=$sample.me.srt.bam OUTPUT=$sample.me.rmdup.srt.bam METRICS_FILE=$sample.me.rmdup.srt.metrics VALIDATION_STRINGENCY=LENIENT > $sample.me.rmdup.srt.log 2>&1  \" > $script`;
    # Merge clipped and merged alignments
	#`echo \"$samtools merge -rf $sample.sp.srt.bam $sample.me.srt.bam $sample.clip.srt.bam >& $sample.merge.log\" >> $script`;
	`echo \"java -Xmx2g -jar /usr/local/SwiftSeq/picard-tools-1.74/MergeSamFiles.jar MAX_RECORDS_IN_RAM=6000000 TMP_DIR=$picard_temp  O=$sample.sp.srt.bam  I=$sample.me.srt.bam I=$sample.clip.srt.bam SO=coordinate AS=true USE_THREADING=true VALIDATION_STRINGENCY=SILENT >& $sample.final.merge.log\" >> $script`;

	# Merge rmdupped clipped and merged alignments
	#`echo \"$samtools merge -rf $sample.sp.rmdup.srt.bam $sample.me.rmdup.srt.bam $sample.clip.rmdup.srt.bam > $sample.rmdup.merge.log 2>&1\" >> $script`;    
	`echo \"java -Xmx2g -jar /usr/local/SwiftSeq/picard-tools-1.74/MergeSamFiles.jar MAX_RECORDS_IN_RAM=6000000 TMP_DIR=$picard_temp  O=$sample.sp.rmdup.srt.bam  I=$sample.me.rmdup.srt.bam I=$sample.clip.rmdup.srt.bam SO=coordinate AS=true USE_THREADING=true VALIDATION_STRINGENCY=SILENT >& $sample.final.rmdup.merge.log\" >> $script`;
    
	# Generate flagstats
    `echo \"$samtools flagstat $sample.sp.srt.bam > $sample.sp.srt.bam.flagstats\" >> $script`;
    `echo \"$samtools flagstat $sample.sp.rmdup.srt.bam > $sample.sp.rmdup.srt.bam.flagstats\" >> $script`;

	# Estimate insert size
	`echo \"$samtools view $sample.sp.rmdup.srt.bam | head -n 2000000 | /glusterfs/users/JGRUNDSTAD/PROJECTS/bin/getinsertsize.py - > $sample.insert_size.txt\" >> $script`;
    
	# Collect Enrichment stats
    `echo \"$bedtools/genomeCoverageBed -ibam $sample.sp.rmdup.srt.bam -g $refseq_bed | grep genome > $sample.genome.covWhist\" >> $script`;
	`echo \"$bedtools/genomeCoverageBed -bga -ibam $sample.sp.rmdup.srt.bam -g $refseq_bed | grep -w 0\$  > $sample.genome.covWhist.zero\" >> $script`;
	`echo \"cat $sample.genome.covWhist.zero | awk 'BEGIN{tot=0}{tot+=(\\\$3-\\\$2)}END{print tot}' > $sample.genome.covWhist.zero.total_bases\" >> $script`;
	push @samtools_cmds, "qsub $samtools_qsub_args $script";
}
$bot->batch('final_samtools');
$bot->max_jobs($max_nodes*8);
$bot->jobs(\@samtools_cmds);
$bot->submit_jobs();

`date >> PE_processing_DONE`;
