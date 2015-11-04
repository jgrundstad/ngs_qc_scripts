#!/bin/bash

FILE_LIST=$1
CONVERT=/lustre/beagle/jgrundst/src/ngs_qc_scripts/convert_to_sanger/convert_stream_illumina-sanger.pl
PIGZ=/lustre/beagle/jgrundst/TRIMMING_TEST/pigz-2.3.3/pigz

OUTDIR=/lustre/beagle2/jgrundst/PDX_trimming/CONVERTED

cat $FILE_LIST | xargs -IFILE -P 5 -n 1 bash -c "zcat FILE | perl $CONVERT | $PIGZ -p 5 -c - > $OUTDIR/FILE && echo FILE >> converted_files.txt"
