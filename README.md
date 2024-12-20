# Arabinosyl-hydroxy-cytosine DNA modification enables phages to evade DNA-targeting but not RNA-targeting CRISPR-Cas
This repository contains the code for the bioinformatics analysis included in [Mahler _et al._ 2025](link).

## Structure
* `bin/` - Scripts used for the analysis
* `docs/` - Document files
* `data/` - Data output (large, not included in **git**)
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
   At the moment, the best way to download genomes is using the script bin/fetch_ncbi-genomes-by-accession.sh.
   This task is currently wrapped in a jupyter notebook that fetches all phage accession IDs via ENTREZ. It also loads accessions IDs from the supplementary table 'phages'.
   Accession IDs are exported as txt files and passed to the bash script. 
   ```
   jupyter execute query_ncbi-genomes.ipynb
   ```
1. Import genomes for analysis
   So far this lacks a lot... . Generally import depends on the file structure specifications and I have to better describe the options (A,B,C).
   Currently I try defining a base structure that works for a single genome but also groups. This should have a simple import function that can be call iteratively for many groups (min.size = 1).
   ```
   jupyter execute query_ncbi-genomes.ipynb
   ```
1. Harmonization of phage annotations
   Currently included in the script above.
   Waiting for better description.
   ```
   ...
   ```

## Citation
If you re-use code from this analysis please cite ...
