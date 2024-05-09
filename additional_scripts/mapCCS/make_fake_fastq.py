## Take barcodes from barcode-seq association file and make fake fastq file

import sys

bc_file = open(sys.argv[1], "r")
fastq_file = open(sys.argv[2], "w")
sample = sys.argv[3] #CYP2C9_PB1

# Read through barcodes, write to fake fastq file
for line in bc_file:
	barcode = line.split('\t')[0]
	fastq_file.write("@"+sample+"\n")
	fastq_file.write(barcode+"\n")
	fastq_file.write("+\n")
	fastq_file.write("A"*len(barcode)+"\n") #arbitrary quality scores
fastq_file.close()
bc_file.close()
