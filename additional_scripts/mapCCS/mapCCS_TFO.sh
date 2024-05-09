#!/bin/bash
#$ -S /bin/bash
#$ -l mfree=16G -l h_rt=1:0:0:0
#$ -cwd
#$ -N CCS_analysis
#$ -o /net/fowler/vol1/home/poppn/pacbio_IanHull/analysis/results
#$ -e /net/fowler/vol1/home/poppn/pacbio_IanHull/analysis/errors

export PACBIO=/net/shendure/vol1/home/mkircher/bin/

# export PACBIO=/net/shendure/vol10/projects/subassemblyByPacBio/src/smrtanalysis/smrtcmds/bin/

module load python/2.7.13
module load pysam/0.16.0.1
module load gmp/6.1.2 mpfr/4.0.1 mpc/1.1.0 gcc/8.2.0
module load bwa/0.7.17

FASTQ=/net/fowler/vol1/home/poppn/pacbio_IanHull/TFO_CSR-DMS_library.IH/DEMUX_10258/demultiplex.bc2011--bc2011.hifi_reads.fastq.gz #full path to input ccs fastq file (can be gzipped)
REF=/net/fowler/vol1/home/poppn/pacbio_IanHull/analysis/reference/barcoded-tfo-wt-xbai-digested-24bp-barcode-removed.fasta  #Full path to reference fasta
OUTDIR=/net/fowler/vol1/home/poppn/pacbio_IanHull/analysis/results/mapCCS/ #path to output directory
SAMPLE=IH_TFO #name of sample eg: CYP2C9_PB1

# Index reference (only run once)
bwa index -a is $REF
$PACBIO/samtools faidx $REF

# Align reads:
# -C (append fasta comment to output ?)  -M (mark shorter split hits as secondary) -L 80 (increase clipping penalty)
/net/shendure/vol1/home/mkircher/bin/bwa_new mem -C -M -L 80 $REF $FASTQ | /net/shendure/vol1/home/mkircher/bin/samtools view -uS - | /net/shendure/vol1/home/mkircher/bin/samtools sort - ${OUTDIR}/${SAMPLE}_ccs_aligned

# Not sure why using modified samtools for flagstat, but this is what was in script
/net/shendure/vol1/home/mkircher/bin/mod_samtools/samtools flagstat ${OUTDIR}/${SAMPLE}_ccs_aligned.bam > ${OUTDIR}/${SAMPLE}_ccs_aligned_stats.txt

# Get rid of extra flags in bam file
$PACBIO/samtools view -h ${OUTDIR}/${SAMPLE}_ccs_aligned.bam | cut -f -14 | $PACBIO/samtools view -Sb - > ${OUTDIR}/${SAMPLE}_ccs_aligned.fix.bam

# Check CIGAR strings (samtools version not specified here, using PacBio version)
$PACBIO/samtools view ${OUTDIR}/${SAMPLE}_ccs_aligned.fix.bam | cut -f 6 | sort| uniq -c | sort -nr > ${OUTDIR}/${SAMPLE}_cigars.txt

# Make file of BC/sequence
# -s flag considers soft clipped reads (default is off)
# Using Melissa's edited version, but commented out the only print statement so the output can go right to a text file.
## NEED TO INPUT COORDINATES of bc (-l) length, (-p) position (start of barcode), and protein coding sequence (--start) start and (--end) end 
## python, so 0-base (subtract one from map for positions)
/net/fowler/vol1/home/poppn/pacbio_IanHull/analysis/scripts/mapCCS/extractBarcodeInsertPairs_moreQC.py --verbose ${OUTDIR}/${SAMPLE}_ccs_aligned.fix.bam -l 24 -p 5046 --start 41 --end 1721 > ${OUTDIR}/${SAMPLE}_seq_barcodes.txt

#unify barcodes: take most common sequence or best quality
/net/fowler/vol1/home/poppn/pacbio_IanHull/analysis/scripts/mapCCS/unifyAssignment.py ${OUTDIR}/${SAMPLE}_seq_barcodes.txt | gzip -c > ${OUTDIR}/${SAMPLE}_combined_minQ0_assignment.tsv.gz
gunzip ${OUTDIR}/${SAMPLE}_combined_minQ0_assignment.tsv.gz

#From there I use that minQ0_assignment to generate a fake fastq file that I can then input into enrich2. The minQ0_assignment file itself serves as your barcode-variant map that you use in enrich2.
python /net/fowler/vol1/home/poppn/pacbio_IanHull/analysis/scripts/mapCCS/make_fake_fastq.py ${OUTDIR}/${SAMPLE}_combined_minQ0_assignment.tsv ${OUTDIR}/${SAMPLE}_BC_only.fastq ${SAMPLE}
python /net/fowler/vol1/home/poppn/pacbio_IanHull/analysis/scripts/mapCCS/make_fake_fastq.py ${OUTDIR}/${SAMPLE}_seq_barcodes.txt ${OUTDIR}/${SAMPLE}_BC_only_uncompressed.fastq ${SAMPLE}

gzip ${OUTDIR}/${SAMPLE}_BC_only.fastq
gzip ${OUTDIR}/${SAMPLE}_BC_only_uncompressed.fastq
