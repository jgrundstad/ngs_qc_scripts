#!/bin/bash
# Jason Grundstad
# 05/08/2014
# Pass 2 raw paired-end fastq data files through SeqPrep, and convert output to single, unaligned BAM
# 

#-------CALL-------
#fastq2bam.sh -s /lustre/beagle/jgrundst/... -1 fq1 -2 fq2

while getopts “s:1:2:mh” opt; do
  case $opt in
    1)
      FQ1=$OPTARG
      ;;
    2)
      FQ2=$OPTARG
      ;;
    s)
	  SEQPREP=$OPTARG
      ;;
	m)
	  MERGE=1
	  ;;
	h)
	  echo "-s	/path/to/SeqPrep <optional>"
	  echo "-1	fastq #1"
	  echo "-2	fastq #2"
	  echo "-m	Perform SeqPrep's read merging functionality"
	  echo "-h	this help message"
	  exit 0
	  ;;
    \?)
      echo “Invalid option specified.”
      exit 1;
      ;; 
  esac
done

SEQPREP=$([[ -z $SEQPREP ]] && echo seqprep || echo $SEQPREP)

echo $SEQPREP

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
SP_ME_BAM="$SAMPLE.me.bam"
FINAL_BAM="$SAMPLE.bam"

# make temporary picard_temp dir
PICARD_TEMP="$SAMPLE.picard_temp"

# Clip adapters, merge (when required) overlapping paired ends into third, single-end file
if [ -z $MERGE ]; then
	$SEQPREP -6 -f $FQ1 -r $FQ2 -1 $FQC1 -2 $FQC2 > $SAMPLE.sp.log 2>&1
else
	echo "$SEQPREP -6 -f $FQ1 -r $FQ2 -1 $FQC1 -2 $FQC2 -s $ME"
	$SEQPREP -6 -f $FQ1 -r $FQ2 -1 $FQC1 -2 $FQC2 -s $ME > $SAMPLE.sp.log 2>&1
	# convert the merged .fastq to .bam
	java -Xmx2g -jar $PICARD_DIR/FastqToSam.jar TMP_DIR=$PICARD_TEMP FASTQ=$ME OUTPUT=$SP_ME_BAM \
	    READ_GROUP_NAME=$SAMPLE.me SAMPLE_NAME=$ID LIBRARY_NAME=$ID PLATFORM=illumina QUALITY_FORMAT=Standard \
		SORT_ORDER=unsorted VALIDATION_STRINGENCY=LENIENT > $SAMPLE.me.convert.log 2>&1
fi

# required for picard ops
mkdir -p $PICARD_TEMP

# convert pair
java -Xmx2g -jar $PICARD_DIR/FastqToSam.jar TMP_DIR=$PICARD_TEMP FASTQ=$FQC1 FASTQ2=$FQC2 OUTPUT=$FINAL_BAM \
	READ_GROUP_NAME=$SAMPLE SAMPLE_NAME=$ID LIBRARY_NAME=$ID PLATFORM=illumina QUALITY_FORMAT=Standard \
	SORT_ORDER=unsorted VALIDATION_STRINGENCY=LENIENT> $SAMPLE.clip.convert.log 2>&1

# cleanup
rm -rf $PICARD_TEMP
rm $FQC1 $FQC2 $ME

# fix mode
chmod 644 $ID*
