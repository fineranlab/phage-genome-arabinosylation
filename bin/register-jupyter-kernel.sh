#/bin/bash

# Setting up the conda environment and installing all programs needed for the analysis.
#
# Conda envs need to be installed via prefix (-p) in the projects directory (/projects/.../envs/)
# as specified in $env_dir while the installation of miniconda is expected in the home directory (/home/$USER).

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

# Check mamba installation
#conda install -c conda-forge mamba -y


# Create conda environment
env_dir='.envs'
env_prefix=main
env_name=phage-genome-arabinosylation
env_yml=envs/main.yml
prefix=$env_dir/$env_prefix

## Create from file
if [ -d $prefix ]; then
  echo "Environment exists. Registering jupyter kernels..."
else
  echo "Environment missing. Please run bin/setup-conda-env.sh"
  exit 1
  #mamba env create --prefix $prefix -f $env_yml -y
fi

## Activate
conda activate $prefix

# Register Jupyter kernels
python -m ipykernel install --user --name Python_$env_name --display-name Python_$env_name
R --slave -e "IRkernel::installspec(name='R_$env_name', displayname='R_$env_name')"
