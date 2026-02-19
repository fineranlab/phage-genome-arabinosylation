#/bin/bash

# Setting up conda environments with all programs needed for the analysis.
#
# Conda envs need to be installed via prefix (-p) in the projects directory (.envs/)
# as specified in $env_dir while the installation of miniconda is expected in the general projects directory (/home/$USER/fineranlab).

# Initialize conda
__conda_setup="$('/home/$USER/fineranlab/miniconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/$USER/fineranlab/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/home/$USER/fineranlab/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/home/$USER/fineranlab/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup

# User info
hostname
date

# Check mamba installation
cmd=$(command -v mamba)
if [[ -z $cmd ]]; then
  echo "Mamba not detected, installing..."
  conda install -c conda-forge mamba -y
elif [[ -n "$cmd" ]]; then
  echo "Mamba detected in $cmd "
fi

# Variables
yml_dir='envs'
env_dir='.envs'

# Install named environments
for i in main;
do
  env_yml=$yml_dir/$i.yml
  prefix=$env_dir/$i
  echo ""
  echo "Installing $env_yml as $prefix"

  ## Create from file
  if [ -d $prefix ]; then
    echo "Environment exists. Installation skipped, to re-install please remove conda env."
  else
    mamba env create --prefix $prefix -f $env_yml -y
  fi

done
