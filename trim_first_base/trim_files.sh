#!/bin/bash

FILE_LIST=$1
TRIM=/lustre/beagle/jgrundst/src/ngs_qc_scripts/trim_first_base/trim_first_base.pl
PIGZ=/lustre/beagle/jgrundst/TRIMMING_TEST/pigz-2.3.3/pigz

cat $FILE_LIST | xargs -IFILE -P 5 -n 1 bash -c "zcat FILE | perl $TRIM | $PIGZ -p 5 -c - > FILE.tmp && mv FILE.tmp FILE && echo FILE >> trimmed_files.txt"
