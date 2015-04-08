#!/bin/bash

ID=$1
ls $ID_*gz | xargs -P 16 -n 1 -iFILE bash -c "zcat FILE | python /lustre/beagle/jgrundst/src/ngs_qc_scripts/test_quality_threshold.py -t j -f FILE" >> /lustre/beagle/jgrundst/j_qual_check.txt

