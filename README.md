# Phage arabinosyl-hydroxy-cytosine DNA modifications result in distinct evasion and sensitivity responses to phage defence systems
This repository contains the code for the bioinformatics analysis included in [Mahler _et al._ 2025](https://doi.org/10.1016/j.chom.2025.06.005).

## Structure
* `bin/` - Scripts used for the analysis
* `docs/` - Supplementary tables
* `data/` - Raw data and intermediates (large, not included in **git**)
* `analysis/` - Analysis output (not included in **git**)
* `envs/` - **conda** environment YAML files
* `LICENSE` - The project license

## Usage
To reproduce the analysis please

1. Install [conda](https://docs.conda.io/en/latest/miniconda.html#) (follow instructions and accept defaults)
   ```
   curl -o miniconda.sh https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
   bash miniconda.sh
   rm miniconda.sh
   source ~/miniconda3/bin/activate
   ```
1. Install [mamba](https://mamba.readthedocs.io/en/latest/installation.html)
   ```
   conda install -c bioconda mamba -y
   mamba init
   ```
1. Clone and enter the git repository (if you want to specify the directory replace '~' with your local path)
   ```
   cd ~
   git clone https://github.com/fineranlab/arabinosylation-anti-CRISPR.git
   cd arabinosylation-anti-CRISPR
   ```
1. Create conda environments
   ```
   mamba env create -f envs/main.yml
   ```
1. Download genomes
   ```
   jupyter execute A_download-genomes.ipynb
   ```
   > Genome accession IDs are retrieved via R's rentrez package and passed to an internal wrapper around NCBI's datasets CLI
1. Analyze arabinosylation genes in phage genomes
   ```
   jupyter execute B_detect-arabinosylation-genes.ipynb
   ```
   > Analysis of genes involved in DNA arabinosylation in multiple collections of phage genomes

## Citation
If you re-use code from this analysis please cite
> Mahler, Marina et al. “Phage arabinosyl-hydroxy-cytosine DNA modifications result in distinct evasion and sensitivity responses to phage defense systems.” Cell host & microbe, S1931-3128(25)00234-3. 24 Jun. 2025, doi:10.1016/j.chom.2025.06.005
