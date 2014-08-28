#!/bin/bash
# replace .bam file for given sample directory with .bam containing
# only header info

DIR=$1

cd $DIR
samtools view -H $DIR.bam | samtools view -H -Sb - > tmp.bam
mv tmp.bam $DIR.bam
