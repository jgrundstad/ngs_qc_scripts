#!/bin/bash
# Jason Grundstad
# 05/08/2014
# Pass 2 raw paired-end fastq data files, and convert output to single, unaligned BAM
# 

#-------CALL-------
#fastq2bam.sh -s /lustre/beagle/jgrundst/... -1 fq1 -2 fq2

function helptext {
  echo "-1	fastq #1"
  echo "-2	fastq #2"
  echo "-h	this help message"
  exit 0
}

[[ $# -gt 0 ]] || { helptext; }

while getopts “s:1:2:mh” opt; do
  case $opt in
    1)
      FQ1=$OPTARG
      ;;
    2)
      FQ2=$OPTARG
      ;;
	h) helptext >&2
	  ;;
    \?)
      echo “Invalid option specified.”
      exit 1;
      ;; 
  esac
done

SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# Bionimbus ID:  2014-1234
ID=$(echo $FQ1 | cut -f1 -d "_")
# Sample_run_lane stub
SAMPLE=$(echo $FQ1 | cut -f1-6 -d "_")
echo "ID: $ID	SAMPLE: $SAMPLE"

# output file names
# FastqToSam
FINAL_BAM="$SAMPLE.bam"

# make temporary picard_temp dir
PICARD_TEMP="$SAMPLE.picard_temp"

# required for picard ops
mkdir -p $PICARD_TEMP

FQ1_CONV=$FQ1.conv.gz
FQ2_CONV=$FQ2.conv.gz

ls $FQ1 $FQ2 | xargs -IFILE -P 2 -n 1 bash -c \
	"zcat FILE | $SCRIPT_DIR/convert_stream_illumina-sanger.pl | gzip -c - > FILE.conv.gz"

# pause to let MDS catch up
sleep 60

# convert pair
java -Xmx2g -jar $PICARD_DIR/FastqToSam.jar TMP_DIR=$PICARD_TEMP FASTQ=$FQ1_CONV FASTQ2=$FQ2_CONV OUTPUT=$FINAL_BAM \
	READ_GROUP_NAME=$SAMPLE SAMPLE_NAME=$ID LIBRARY_NAME=$ID PLATFORM=illumina QUALITY_FORMAT=Standard \
	SORT_ORDER=unsorted VALIDATION_STRINGENCY=LENIENT VERBOSITY=DEBUG > $SAMPLE.convert.log 2>&1

# cleanup
rm -rf $PICARD_TEMP
rm $FQ1_CONV $FQ2_CONV

# fix mode
chmod 644 $ID*
