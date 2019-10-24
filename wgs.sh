#!/usr/bin/env bash

# Global variables.
reads_dir=fastq
file=EchF_R1.fastq.gz
output_dir=results

# Input files.
name_R1=$(echo $file|sed "s:$reads_dir\/::g")
name_R2=$(echo $file|sed "s:R1:R2:g"|sed "s:$reads_dir\/::g")
echo "Files used: $name_R1 $name_R2"

# Unzip the two fastq files.
gunzip $reads_dir/$name_R1 $reads_dir/$name_R2

# Compile samtools, uncomment to use.
: '
cd soft/samtools-1.6
./configure
make
cd -
'

mkdir $output_dir


# Naive way to get the fastq without .gz extension.
fastq_R1=$(echo $name_R1|sed "s:\.gz::g")
fastq_R2=$(echo $name_R2|sed "s:\.gz::g")
echo $fastq_R1 $fastq_R2

# Align sample to genomes.

soft/bowtie2 -1 $reads_dir/$fastq_R1 -2 $reads_dir/$fastq_R2 \
             -x databases/all_genome.fasta -S $output_dir/alignments.sam \
             --end-to-end --fast 

# Convert SAM to BAM.
soft/samtools-1.6/samtools view -b -1 $output_dir/alignments.sam > $output_dir/alignments.bam

# Sort the BAM.
soft/samtools-1.6/samtools sort $output_dir/alignments.bam -o $output_dir/alignments.sorted.bam

# Index the BAM.
soft/samtools-1.6/samtools index $output_dir/alignments.sorted.bam

# Extract the count table.
soft/samtools-1.6/samtools idxstats $output_dir/alignments.sorted.bam > $output_dir/count_table.tsv

# Associate gi to annotation.
grep ">" databases/all_genome.fasta|cut -f 2 -d ">" > $output_dir/association.tsv

# Assemble the genome.
soft/megahit -1 $reads_dir/$fastq_R1 -2 $reads_dir/$fastq_R2 \
             -o $output_dir/megahit \
             --k-list 21 --mem-flag 0 

# Predicting genes.
soft/prodigal -i $output_dir/megahit/final.contigs.fa -d $output_dir/genes.fna

# Select full genes.
sed "s:>:*\n>:g" $output_dir/genes.fna | sed -n "/partial=00/,/*/p"|grep -v "*" > $output_dir/genes_full.fna

# Annotate the full genes.
soft/blastn -db databases/resfinder.fna -query $output_dir/genes_full.fna -out $output_dir/annotated_genes.txt -evalue 0.001 -perc_identity 80 -qcov_hsp_perc 80

# By parsing annotated_genes.txt, it does not seem like there are hits founds against resfinder.fna so we can suppose that there are no resistance genes found

