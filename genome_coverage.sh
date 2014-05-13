#!/bin/bash
#PBS -N genome_cov
#PBS -l nodes=1:ppn=2
#PBS -j oe
cd $PBS_O_WORKDIR

REFBED=/glusterfs/SEQreference/hg18.genome.bed
BEDTOOLS=/glusterfs/users/caseybrown/SEQanalysis/BEDTools-Version-2.13.4/bin
#$bedtools/genomeCoverageBed -ibam $sample.sp.rmdup.srt.bam -g $refseq_bed | grep genome > $sample.genome.covWhist
$BEDTOOLS/genomeCoverageBed -ibam $SAMPLE.merged.bam -g $REFBED | grep genome > $SAMPLE.genome.covWhist
