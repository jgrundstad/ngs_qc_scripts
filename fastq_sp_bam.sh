#!/bin/bash
# Jason Grundstad
# 05/08/2014
# Pass raw paired-end fastq data through SeqPrep, and convert output to single, unaligned BAM
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
ME="$SAMPLE.me.fq.gz"
# FastqToSam
SP_CLIP_BAM=$SAMPLE.clip.bam
SP_ME_BAM=$SAMPLE.me.bam
# MergeSamFiles
FINAL_BAM=$SAMPLE.bam

# make temporary picard_temp dir
SEQPREP="/lustre/beagle/jgrundst/TOOLS/seqprep/SeqPrep"
PICARD_TEMP="$SAMPLE.picard_temp"

# Clip adapters, merge overlapping paired ends into third, single-end file
$SEQPREP -f $FQ1 -r $FQ2 -1 $FQC1 -2 $FQC2 -s $ME > $SAMPLE.sp.log 2>&1

# required for picard ops
mkdir -p $PICARD_TEMP

# convert pair
java -Xmx2g -jar $PICARD_DIR/FastqToSam.jar TMP_DIR=$PICARD_TEMP FASTQ=$FQC1 FASTQ2=$FQC2 OUTPUT=$SP_CLIP_BAM \
	READ_GROUP_NAME=$SAMPLE SAMPLE_NAME=$SAMPLE LIBRARY_NAME=$SAMPLE PLATFORM=illumina QUALITY_FORMAT=Standard \
	SORT_ORDER=unsorted > $SAMPLE.clip.convert.log 2>&1

# convert merged
java -Xmx2g -jar $PICARD_DIR/FastqToSam.jar TMP_DIR=$PICARD_TEMP FASTQ=$ME OUTPUT=$SP_ME_BAM \
	READ_GROUP_NAME=$SAMPLE.me SAMPLE_NAME=$SAMPLE LIBRARY_NAME=$SAMPLE PLATFORM=illumina QUALITY_FORMAT=Standard \
	SORT_ORDER=unsorted > $SAMPLE.me.convert.log 2>&1

# merge converted bams
java -Xmx2g -jar $PICARD_DIR/MergeSamFiles.jar TMP_DIR=$PICARD_TEMP INPUT=$SP_CLIP_BAM INPUT=$SP_ME_BAM \
	OUTPUT=$FINAL_BAM SORT_ORDER=unsorted ASSUME_SORTED=false > $SAMPLE.merge.log 2>&1

# cleanup
rm -rf $SAMPLE.picard_temp
rm $FQ1 $FQ2 $FQC1 $FQC2 $ME $SP_CLIP_BAM $SP_ME_BAM
