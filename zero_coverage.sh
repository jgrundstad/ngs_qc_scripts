#!/bin/bash
BAMFILE=$1
FILENAME=$(basename $BAMFILE)
REF_BED='/lustre/beagle/jgrundst/REF/human_g1k_v37.bed'

genomeCoverageBed -bga -ibam $BAMFILE -g $REF_BED | grep -w 0\$ > $FILENAME.zero_coverage.txt

