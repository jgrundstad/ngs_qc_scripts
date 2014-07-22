#!/bin/bash

function helptext {
  echo "Output the zero and low coverage regions of a .bam over a given genomic reference .bed."
  echo "-b  input .bam"
  echo "-t  max non-zero coverage to keep as \"low_coverage.bed\" output"
  echo "-r  reference .bed"
  echo "-h  this message"
  echo ""
  exit 0
}

[[ $# -gt 0 ]] || { helptext; }

while getopts "b:r:h" opt; do
	case $opt in
		b)
		  BAMFILE=$OPTARG
		  FILENAME=$(basename $BAMFILE)
		  ;;
		r)
		  REF_BED=$OPTARG
		  ;;
		h)
		  helptext >&2
		  ;;
		\?)
		  echo "Invalid option specified."
		  exit 1;
		  ;;
	esac
done

genomeCoverageBed -bga -ibam $BAM -g $REF_BED | awk "{if(\$4==0) {print > \""$FILENAME.zero_coverage.bed"\";} else if(\$4<=7) {print > \""$FILENAME.low_coverage.bed"\";}}"
