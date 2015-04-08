#!/bin/bash
LIST=$1

cat $LIST | xargs -iJGJG grep JGJG. file_list.txt | xargs -iINFILE -n 1 -P 20 /lustre/beagle/jgrundst/src/ngs_qc_scripts/zero_coverage.sh INFILE
#cat $LIST | xargs -iJGJG grep JGJG. file_list.txt | xargs -iINFILE echo INFILE

