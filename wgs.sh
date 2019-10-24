#!/usr/bin/env bash

# Global variables.
reads_dir=fastq
file=EchF_R1.fastq.gz

# Input files.
name_R1=$(echo $file|sed "s:$reads_dir\/::g")
name_R2=$(echo $file|sed "s:R1:R2:g"|sed "s:$reads_dir\/::g")
echo "Files used: $name_R1 $name_R2"

# Unzip the two fastq files.
gunzip $reads_dir/$name_R1 $reads_dir/$name_R2

# Naive way to get the fastq without .gz extension.
fastq_R1=$(echo $name_R1|sed "s:\.gz::g")
fastq_R2=$(echo $name_R2|sed "s:\.gz::g")
echo $fastq_R1 $fastq_R2

# -q fastq --end-to-end --fast
soft/bowtie2 -1 fastq/EchF_R1.fastq -2 fastq/EchF_R2.fastq \
             -x databases/all_genome.fasta -S alignments.sam \
             --end-to-end --fast 

