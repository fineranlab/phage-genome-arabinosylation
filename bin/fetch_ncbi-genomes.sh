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
   echo "-t	Genome type (genome OR virus genome)"
   echo "-V	Print software version and exit."
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

echo '-- Checking input arguments --'

# Check inputfile
if [[ -e $inputfile ]]; then
  echo Getting accession numbers from $inputfile
else
  echo 'Error: no inputfile present, aborting.'
  exit 1
fi

# Check output directory
if [[ -d $output ]]; then
  echo 'Error: Output directory already exists, aborting..'
  exit 2
elif [ $output=none ]; then
  output=$(dirname $inputfile)/genomes
  echo No output directory specified. Defaulting to $output
fi

# Check type
if [[ $type == 'genome' ]]; then
  echo Query type: $type
elif [[ $type == 'virus genome' ]]; then
  echo Query type: $type
else
  echo Query type: $type not possible. Aborting
  exit 3
fi

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
conda_count=$(conda env list | grep -c $conda_env) # there can be only one line!
if [ $conda_count != 1 ]; then
  echo 'No available conda environment specified.'
else
  echo Activating $conda_env
  conda activate $conda_env
fi

# Variables
dir=$(dirname $inputfile)/

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
outputfile=$output.zip
datasets download $type accession \
	--inputfile $inputfile \
	--filename $outputfile \
	--include annotation,biosample,cds,genome,protein

## Extract archive
unzip $outputfile -d $output

## Rehydrate archive
if [[ necessary ]]; then
  datasets rehydrate --directory $output # FIND OUT WHEN NECESSARY !!!
fi

## Convert GTF format
gtf_fields='accession,gene-cds-name,gene-cds-nuc-fasta-title,gene-cds-nuc-fasta-seq-id,gene-cds-nuc-fasta-range-start,gene-cds-nuc-fasta-range-stop,gene-cds-protein-fasta-accession,gene-cds-protein-fasta-seq-id,gene-cds-protein-fasta-title'
ann_report=$output/ncbi_dataset/data/annotation_report.jsonl
gtf=$output/ncbi_dataset/data/annotation.gtf
dataformat tsv virus-annotation --fields $gtf_fields --inputfile $ann_report > $gtf
