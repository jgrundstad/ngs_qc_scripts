#!/bin/bash

function helptext {
  echo "Output the zero and low coverage regions of a .bam over a given genomic reference .bed."
  echo "-b  input .bam"
  echo "-t  max non-zero coverage to keep as \"low_coverage.bed\" output"
  echo "-r  reference .bed"
  echo ""
  exit 0
}

[[ $# -gt 0 ]] || { helptext; }

while getopts "b:r:t:" OPTION; 
do
	case $OPTION in
	b)
	  BAMFILE=$OPTARG
	  ;;
	r)
	  REF_BED=$OPTARG
	  ;;
	t)
	  THRESHOLD=$OPTARG
	  ;;
	\?)
	  echo "Invalid option specified."
	  exit 1;
	  ;;
	esac
done

FILENAME=$(basename $BAMFILE)

function splitter {
    while read data; do
		LINE=$data
		COV=$(echo $data | cut -d " " -f4)
		#echo $COV
		if [ $COV -eq 0 ]
		then
			echo $LINE >> $FILENAME.zero_coverage.bed;
		elif [ $COV -le $THRESHOLD ]
		then
			echo $LINE >> $FILENAME.low_coverage.bed;
		fi;
	done;
}

genomeCoverageBed -bga -ibam $BAMFILE -g $REF_BED | splitter

# awk stores too much in RAM... 
#genomeCoverageBed -bga -ibam $BAMFILE -g $REF_BED | awk "{if(\$4==0) {print > \""$FILENAME.zero_coverage.bed"\";} else if(\$4<=\$THRESHOLD) {print > \""$FILENAME.low_coverage.bed"\";}}"
