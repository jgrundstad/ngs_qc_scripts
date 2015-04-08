#!/bin/bash

module load bwa
cd $1
FASTQ=$(ls $1*sequence.txt.gz)
bwa mem -t 20 /lustre/beagle/jgrundst/REF/bwa/human_g1k_v37.fasta $FASTQ | samtools view -Sb -h - > $FASTQ.bam
