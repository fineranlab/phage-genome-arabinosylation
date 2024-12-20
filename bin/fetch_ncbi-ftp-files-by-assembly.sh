#!/bin/bash

# Functions --------------------------------------------------------------------
Help() {
   # Display help
   echo "Download from NCBI FTP."
   echo "Takes a file of assembly accession numbers with FTP path, creates directory structure."
   echo
   echo "Syntax: scriptTemplate [-h|i|e|o|V]"
   echo "options:"
   echo "-h     Print this help"
   echo "-i     Input file"
   echo "-e     Conda environment"
   echo "-o     Output directory (default: genomes/)"
   echo "-t     Genome type (genome OR virus genome)"
   echo "-V     Print software version and exit."
   echo
}

# Process input options --------------------------------------------------------
inputfile=none
conda_env=none
output=none
type=genome
while getopts "hi:e:o:t:V" option; do
   case $option in
      h) # display Help
         Help
         exit;;
      i) # Enter the input file
         inputfile=$OPTARG;;
      e) # Enter the conda environment
         conda_env=$OPTARG;;
      o) # Enter the output directory
         output=$OPTARG;;
      t) # Enter the genome type
         type=$OPTARG;;
      V) # Software version
         echo "No version issued."
         exit;;
     \?) # Invalid option
         echo "Error: Invalid option"
         exit;;
   esac
done

