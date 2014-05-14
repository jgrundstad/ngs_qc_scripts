#!/bin/bash

DIR=$1
cd $DIR
PWD=pwd
echo "$PWD"
#2013-2117_140318_SN673_0216_BC3YHHACXX_3_1_sequence.txt.gz
ls *_1_sequence.txt.gz | cut -f1-6 -d "_" | xargs -iSTUB -n 1 -P 20 /lustre/beagle/jgrundst/ngs_qc_scripts/fastq_sp_bam.sh STUB_1_sequence.txt.gz STUB_2_sequence.txt.gz
