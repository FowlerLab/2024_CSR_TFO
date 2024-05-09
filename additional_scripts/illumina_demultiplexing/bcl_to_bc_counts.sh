#!/bin/bash

## this script demultiplexes an Illumina sequencing run
## then counts the number of reads in each sample
## then pairs the reads
## then extracts the sequenced barcodes (length 18) and counts them

## requirements: 
## SampleSheet.csv in main folder
## barcodes.grp in Data/Intensities/Basecalls

## standard run command: qsub -l mfree=64G -cwd ./bcl_to_bc_counts.sh .

## Nicholas Popp 01.06.21

## ensure errors stop the process instead of powering through
set -e

## time function for assessing time
## arg: name of process
time_function () {
	start=$2
	end=$SECONDS
	runtime=$( echo "$end - $start" | bc -l)
	hours=$((runtime / 3600))
	minutes=$(( (runtime % 3600) / 60 ))
	seconds=$(( (runtime % 3600) % 60 ))
	echo "$1 took $hours:$minutes:$seconds (hh:mm:ss) to complete" >&2
}

## pull start time and write to output file
starttime=$SECONDS
date >&2
echo "Job ${JOB_ID} started on ${HOSTNAME} with ${NSLOTS} slots" >&2

## load modules
module load bcl2fastq/2.20
module load pear/0.9.11

## demultiplex sequencing run
bcl2fastq --no-lane-splitting --minimum-trimmed-read-length 0 --mask-short-adapter-reads 0 -r 5 -p 5 -w 5 --barcode-mismatches=0 --ignore-missing-bcls

## identify time to complete demultiplexing
time_function demultiplexing starttime

## go to fastq files and make subdirectories
cd Data/Intensities/BaseCalls
mkdir csv tsv fastq pear

## unzip fastq files
gunzip *.gz

## identify time to complete unzipping files
time_function "unzipping fastq files" "$end"

## count files
./count_fastq.sh *R1*.fastq >> ./tsv/read_counts.tsv

## identify time to count files
time_function "counting all reads" "$end"

## pair sequencing reads to improve quality IH (24 bp barcodes)
for sample in $(grep -v "^#" barcodes.grp | cut -f 1); do pear -y 64G -m 24 -n 24 -v 24 -j 10 -f ${sample}_R1_001.fastq -r ${sample}_R2_001.fastq -o ${sample}.fastq; done

## pair sequencing reads to improve quality GB (18 bp barcodes)
for sample in $(grep -v "^#" barcodes2.grp | cut -f 1); do pear -y 64G -m 18 -n 18 -v 18 -j 10 -f ${sample}_R1_001.fastq -r ${sample}_R2_001.fastq -o ${sample}.fastq; done

## identify time to pear reads
time_function "pairing reads" "$end"

## count IH barcodes
for sample in $(grep -v "^#" barcodes.grp | cut -f 1); do awk '{if(NR%4==2) print $0}' ${sample}.fastq.assembled.fastq | sort | uniq -c | awk -v sp=$sample 'OFS="," {print $2,$1,sp}' | sort --field-separator=',' -k 2 -n -r > IH_barcode_counts_${sample}.csv; done

## count GB barcodes
for sample in $(grep -v "^#" barcodes2.grp | cut -f 1); do awk '{if(NR%4==2) print $0}' ${sample}.fastq.assembled.fastq | sort | uniq -c | awk -v sp=$sample 'OFS="," {print $2,$1,sp}' | sort --field-separator=',' -k 2 -n -r > GB_barcode_counts_${sample}.csv; done

## concatenate samples together to a single output file
for f in IH_barcode*.csv; do cat "$f" >> IH_all_barcode_counts.csv; done

## identify time to count barcodes
time_function "counting unique barcodes" "$end"

## move all files to final output subdirectories
mv *assembled*.fastq ./pear/
mv *discarded*.fastq ./pear/
mv *.fastq ./fastq/
mv *.csv ./csv/

## final time to complete
date >&2
time_function "entire script" starttime 
