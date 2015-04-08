#!/bin/bash

find -maxdepth 1 -type d -iname "20*" | cut -f2 -d "/" | xargs -P 20 -n 1 -iID bash -c "samtools flagstat ID/ID.bam > ID/ID.bam.flagstats"
