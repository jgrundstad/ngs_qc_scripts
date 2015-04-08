#!/bin/bash
LIST=$1

cat $LIST | xargs -iJGJG grep JGJG. file_list.txt | xargs -iINFILE -n 1 -P 5 /lustre/beagle/jgrundst/src/ngs_qc_scripts/get_low_and_zero_coverage.sh -b INFILE -t 7 -r /lustre/beagle/jgrundst/REF/human_g1k_v37.bed

