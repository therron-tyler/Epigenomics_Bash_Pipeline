#!/bin/bash
#SBATCH -A b1042
#SBATCH -p genomics
#SBATCH -t 48:00:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=tyler.therron@northwestern.edu
#SBATCH --output=%x.%j.out
#SBATCH --mem=105gb
#SBATCH --job-name=_job_name_
#SBATCH -N 1
#SBATCH -n 10

module load bowtie2/2.4.5
module load samtools/1.6
module load homer/4.10
module load bedtools/2.30.0
module load subread/2.0.3
#module load trimmomatic/0.39
module load java


BASE_DIR=$(pwd)

# REPLACE bedtools with HOMER - mergePeaks

mergePeaks *_Peak_Output.txt -strand > all_samples_merged_Peaks.txt
pos2bed.pl all_samples_merged_Peaks.txt > all_samples_merged_Peaks.bed


if [ $? -ne 0 ]; then
    echo "Error after Concatenating, Sorting, and Merging BED files into one Merged BED file. Exiting."
    exit 1
fi

# Creation of annotation SAF

awk 'BEGIN{OFS="\t"; print "GeneID", "Chr", "Start", "End", "Strand"} NR>1 {print $4, $2, $3+1, $4, $5}' all_samples_merged_Peaks.txt > all_samples_HOMERproduced_merged.saf

if [ $? -ne 0 ]; then
    echo "Error after Concatenating, Sorting, and Merging BED files into one Merged BED file. Exiting."
    exit 1
fi


# creating the final count matrix
featureCounts -a ${BASE_DIR}/all_samples_HOMERproduced_merged.saf -o ${BASE_DIR}/20240202_all_samples_counts.txt -F SAF ${BASE_DIR}/*.bam
