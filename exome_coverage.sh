#!/bin/bash
#PBS -N exome_cov
#PBS -l nodes=1:ppn=2
#PBS -j oe
cd $PBS_O_WORKDIR

REFBED=/glusterfs/SEQreference/refseq.Hs18.coding.merged.bed
BEDTOOLS=/glusterfs/users/caseybrown/SEQanalysis/BEDTools-Version-2.13.4/bin
#bedtools/coverageBed -abam $sample.sp.rmdup.srt.bam -b $refseq_bed -hist | grep all > $sample.exome.covWhist
$BEDTOOLS/coverageBed -abam $SAMPLE.merged.bam -b $REFBED -hist | grep all > $SAMPLE.exome.covWhist
