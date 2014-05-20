#!/bin/bash
# Jason Grundstad
# 05/08/2014
# Pass 2 raw paired-end fastq data files through SeqPrep, and convert output to single, unaligned BAM
# 

# Input
FQ1=$1
FQ2=$2

# Bionimbus ID:  2014-1234
ID=$(echo $FQ1 | cut -f1 -d "_")
# Sample_run_lane stub
SAMPLE=$(echo $FQ1 | cut -f1-6 -d "_")
echo "ID: $ID	SAMPLE: $SAMPLE"

# output file names
# Seqprep
FQC1="$FQ1.clip.fq.gz"
FQC2="$FQ2.clip.fq.gz"
FINAL_BAM=$SAMPLE.bam

# make temporary picard_temp dir
SEQPREP="/lustre/beagle/jgrundst/TOOLS/seqprep/SeqPrep"
PICARD_TEMP="$SAMPLE.picard_temp"

# Clip adapters, merge overlapping paired ends into third, single-end file
$SEQPREP -6 -f $FQ1 -r $FQ2 -1 $FQC1 -2 $FQC2 > $SAMPLE.sp.log 2>&1

# required for picard ops
mkdir -p $PICARD_TEMP

# convert pair

java -Xmx2g -jar $PICARD_DIR/FastqToSam.jar TMP_DIR=$PICARD_TEMP FASTQ=$FQC1 FASTQ2=$FQC2 OUTPUT=$FINAL_BAM READ_GROUP_NAME=$SAMPLE SAMPLE_NAME=$ID LIBRARY_NAME=$ID PLATFORM=illumina QUALITY_FORMAT=Standard SORT_ORDER=unsorted VALIDATION_STRINGENCY=LENIENT> $SAMPLE.clip.convert.log 2>&1

# cleanup
rm -rf $PICARD_TEMP
rm $FQ1 $FQ2 $FQC1 $FQC2

# fix mode
chmod 644 $ID*
