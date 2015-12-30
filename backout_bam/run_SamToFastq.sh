#!/bin/bash

function helptext {
	echo "Back out fastq files from provided bam"
	echo "-b	bamfile"
	echo "-t	paired/single"
	echo "-o	output directory"
	echo "-h	this help message"
}

[[ $# -gt 0 ]] || { helptext; exit 1; }

while getopts ":b:t:o:h" opt; do
	case $opt in
		b)
			BAM=$OPTARG
			;;
		t)
			TYPE=$OPTARG
			if [ ${TYPE} != 'paired' ] && [ ${TYPE} != 'single' ]; then
				echo "-t ${TYPE} not recognized.  Use either 'paired' or 'single'."
				echo ""
				helptext
				exit 1
			fi
			;;
		o)
			OUT_DIR=$OPTARG
			;;
		h)
			helptext >&2
			exit 0
			;;
		\?)
			echo "Invalid option specified!"
			helptext >&2
			exit 1
			;;
	esac
done

if [ -z ${TYPE} ] || [ -z ${BAM} ] || [ -z ${OUT_DIR} ]; then
	helptext
	exit 1;
fi

if ! [ -e ${BAM} ]; then
	echo "ERROR: ${BAM} file doesn't exist."
	echo "Exiting."
	exit 1;
fi

FILE_STUB=$(echo ${BAM} | cut -f1 -d '.') # remove .bam extension

PICARD_TEMP=${BAM}.temp
mkdir -p ${BAM}.temp
mkdir -p ${OUT_DIR}

TYPE_OPTIONS=''
if [ ${TYPE} == 'single' ]; then
	TYPE_OPTIONS="FASTQ=${OUT_DIR}/${FILE_STUB}.fastq"
elif [ ${TYPE} == 'paired' ]; then
	TYPE_OPTIONS="FASTQ=${OUT_DIR}/${FILE_STUB}_1.fastq SECOND_END_FASTQ=${OUT_DIR}/${FILE_STUB}_2.fastq"
fi

java -Xmx2g -jar ${PICARD_DIR}/picard.jar SamToFastq \
	TMP_DIR=${PICARD_TEMP} \
	VALIDATION_STRINGENCY=LENIENT \
	INPUT=${BAM} \
	${TYPE_OPTIONS} \
	INCLUDE_NON_PF_READS=true

echo "Compressing fastqs"
cd ${OUT_DIR}
ls *fastq | xargs -IFILE -P 4 -n 1 gzip FILE
