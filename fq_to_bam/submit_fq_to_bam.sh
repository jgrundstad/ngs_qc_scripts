#!/bin/bash
DIR=$1
cd $DIR
PWD=$(pwd)
echo "$PWD"

#2013-2117_140318_SN673_0216_BC3YHHACXX_3_1_sequence.txt.gz
ls *_[1-8]_1_sequence.txt.gz | cut -f1-6 -d "_" | parallel -P 10 /lustre/beagle/jgrundst/src/ngs_qc_scripts/fq_to_bam/fastq_to_bam.sh -1 {}_1_sequence.txt.gz -2 {}_2_sequence.txt.gz

INPUT_STRING=$(ls *bam | parallel echo "I={}" | paste -s -d " ")

mkdir -p final_merge_tmp

#java -Xmx8g -jar $PICARD_DIR/MergeSamFiles.jar TMP_DIR=final_merge_tmp $INPUT_STRING O=$DIR.bam SO=unsorted ASSUME_SORTED=false VERBOSITY=DEBUG USE_THREADING=true VALIDATION_STRINGENCY=LENIENT > $DIR.final.merge.log 2>&1
/lustre/beagle/cbandlam/libs/novosort/novosort --threads 28 --ram 24576M --tmpcompression 6 --tmpdir final_merge_tmp --assumesorted --output $DIR.bam *_[1-8].bam > $DIR.final.novosort.merge.log 2>&1

rm -rf final_merge_tmp

chmod 644 $DIR.bam

samtools flagstat $DIR.bam > $DIR.bam.flagstats

rm *_[1-8].bam
