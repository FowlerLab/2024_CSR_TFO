# Analysis and figures for Hull, et al., Deep Mutational Scan of a DNA Polymerase via Compartmentalized Self-Replication

Requirements:
R 4.0.0 or greater

## Purpose
This repository houses all of the analysis and figures for the Multiplexed Assay of Variant Effect (MAVE) in this paper called Compartmentalized Self-Replication Deep Mutational Scanning (CSR-DMS). It includes an R script that takes processed sequencing data from both short- and long-read sequencing and calculates functional scores for nearly all missense, nonsense, synonymous, and single amino acid deletions in our designed TFO polymerase. It also contains scripts that were used remotely to process our raw Illumina and PacBio sequencing data. Figure panels and analysis products are available in the outputs folder.

## Instructions for use

1. Clone or fork this Github repository

2. Navigate to the downloaded folder. All input and output data should be present already. To run the script on your own, first, you need to run this shell script to unpack the input data.

`sh unzip_input_files.sh`

3. Open R/RStudio and open the 221224_TFO_pacbio_subassembly.Rmd document. This will generate any figures and tables from the PacBio long-read sequencing data that was used to isolate and sequence DNA variants and their respective degenerate barcodes.

4. Next, open the 230227_CSR_scoring.Rmd document in R/RStudio. This will generate the functional scores from the MAVE selection assay (CSR-DMS) and plot heatmaps and other analysis from these data.  
