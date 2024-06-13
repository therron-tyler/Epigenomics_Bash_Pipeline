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
module load java

# this root directory will just have everything in it
BASE_DIR=$(pwd)


# Run Trimmomatic
java -jar /projects/b1063/Reference/Trimmomatic_0.36/trimmomatic_0.36.jar SE -phred33 \
  ${BASE_DIR}/_fastq_gz_file_.fastq.gz \
  ${BASE_DIR}/_fastq_gz_file__trimmed.fastq.gz \
  ILLUMINACLIP:"/projects/b1063/Reference/Trimmomatic_0.36/adapters/TruSeq3-SE.fa":2:30:10 \
  LEADING:3 TRAILING:3 \
  SLIDINGWINDOW:4:15 MINLEN:36

if [ $? -ne 0 ]; then
    echo "Error during Trimmomatic. Exiting."
    exit 1
fi

bowtie2 -x /projects/b1063/Reference/Anno/mm10/bowtie_indices/mm10 -U ${BASE_DIR}/_fastq_gz_file__trimmed.fastq.gz -S ${BASE_DIR}/_fastq_gz_file_.sam

if [ $? -ne 0 ]; then
    echo "Error after alignment. Exiting."
    exit 1
fi

samtools view -bS ${BASE_DIR}/_fastq_gz_file_.sam > ${BASE_DIR}/_fastq_gz_file_.bam

if [ $? -ne 0 ]; then
    echo "Error after sam to bam convert. Exiting."
    exit 1
fi

mkdir ${BASE_DIR}/_fastq_gz_file__HOMER_tag_directory

if [ $? -ne 0 ]; then
    echo "Error after making tag directory. Exiting."
    exit 1
fi

makeTagDirectory ${BASE_DIR}/_fastq_gz_file__HOMER_tag_directory/ ${BASE_DIR}/_fastq_gz_file_.bam -genome /projects/b1063/Reference/Anno/mm10/bowtie_indices/mm10.fa

if [ $? -ne 0 ]; then
    echo "Error after computing sample tag directories. Exiting."
    exit 1
fi

findPeaks ${BASE_DIR}/_fastq_gz_file__HOMER_tag_directory/ -o ${BASE_DIR}/_fastq_gz_file__Peak_Output.txt -center -minDist 1000 -size 500

if [ $? -ne 0 ]; then
    echo "Error after finding Peak peaks. Exiting."
    exit 1
fi

# convert to bed and merge peaks next

pos2bed.pl ${BASE_DIR}/_fastq_gz_file__Peak_Output.txt > ${BASE_DIR}/_fastq_gz_file__Peak_Output.bed

if [ $? -ne 0 ]; then
    echo "Error after HOMER bed conversion. Exiting."
    exit 1
fi

# sort the individual BED files
sort -k1,1 -k2,2n ${BASE_DIR}/_fastq_gz_file__Peak_Output.bed > ${BASE_DIR}/_fastq_gz_file__Output_sorted.bed

if [ $? -ne 0 ]; then
    echo "Error after sorting individual BED files. Exiting."
    exit 1
fi



