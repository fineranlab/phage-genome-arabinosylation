#/bin/bash
#SBATCH --job-name=example-job    # Name of job
#SBATCH --output=%x_%j.log        # stdout
#SBATCH --error=%x_%j.log         # stderr
#SBATCH --partition=gpu           # cpu or gpu, partition to use (check with sinfo)
#SBATCH --gres=gpu:t4:2           # GPU type (t4 or v100) and number (gpu:TYPE:NUMBER)
#SBATCH --nodes=1                 # Number of nodes
#SBATCH --ntasks=2                # Number of tasks
#SBATCH --threads-per-core=1      # Ensure we only get one logical CPU per core
#SBATCH --cpus-per-task=1         # Number of cores per task
#SBATCH --mem=32G                 # Memory per node
#SBATCH --time=48:00:00           # wall time limit (HH:MM:SS)
#SBATCH --mail-type=ALL
#SBATCH --mail-user=oliver.dietrich@otago.ac.nz
#SBATCH --clusters=bioinf

# Functions --------------------------------------------------------------------
Help() {
   # Display help
   echo "Call to NCBI datasets CLI."
   echo "Takes a file of accession numbers, creates directory with ncbi dataset."
   echo
   echo "Syntax: scriptTemplate [-h|i|e|o|V]"
   echo "options:"
   echo "-h	Print this help"
   echo "-i	Input file"
   echo "-e	Conda environment"
   echo "-o	Output directory (default: genomes/)"
   echo "-V	Print software version and exit."
   echo
}

# Process input options --------------------------------------------------------
inputfile=none
conda_env=none
while getopts ":h:i:e:o:V" option; do
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
      V) # Software version
	 echo "No version issued."
	 exit;;
     \?) # Invalid option
         echo "Error: Invalid option"
         exit;;
   esac
done

# Check inputfile
if [[ -e $inputfile ]]; then
  echo 'Getting accession numbers from $inputfile'
else
  echo 'Error: no inputfile present, aborting.'
  exit 1
fi

# Check output directory
if [[ -d $output ]]; then
  echo 'Error: Output directory already exists, aborting..'
  exit 2
fi

# TODO:
# get output path from input file
# check if present
# ...


# Functions --------------------------------------------------------------------
check_installed_programs() {
echo ''
echo '-- Checking for installed programs --'
missing_programs=0
for i in $@; do
  if [[ -e $(which $i 2>&1) ]]; then
    echo $i: $(which $i)
  else
    echo $i: not installed
    missing_programs=$(($missing_programs+1))
  fi
done
echo ''
}

# Conda environment ------------------------------------------------------------
__conda_setup="$('/home/$USER/miniconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/$USER/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/home/$USER/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/home/$USER/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup

# Activate env
if [[ $conda_env=none ]]; then
  echo 'No conda environment specified.'
else
  conda activate $conda_env
fi

# Variables
dir=$(dirname $accession)

# Input errors -----------------------------------------------------------------
check_installed_programs datasets unzip dataformat

if [[ $missing_programs > 0 ]]; then
  echo 'Error: some programs are missing. Consider passing a conda environment using the -e flag.'
  exit 1
fi

# Main program -----------------------------------------------------------------
hostname
date

## Call NCBI datasets CLI
#datasets download virus genome accession \
#	--inputfile $accession \
#	--filename $output \
#	--include annotation,biosample,cds,genome,protein

## Extract archive
#unzip genomes.zip

## Rehydrate archive
# datasets rehydrate --directory genomes/

## Convert GTF format
gtf_fields='accession,gene-cds-name,gene-cds-nuc-fasta-title,gene-cds-nuc-fasta-seq-id,gene-cds-nuc-fasta-range-start,gene-cds-nuc-fasta-range-stop,gene-cds-protein-fasta-accession,gene-cds-protein-fasta-seq-id,gene-cds-protein-fasta-title'
dataformat tsv virus-annotation --fields $gtf_fields --inputfile $ann_report > $gtf
