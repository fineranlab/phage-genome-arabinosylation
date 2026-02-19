# Compile Padloc DB from hmm/

# Remove padlocdb.hmm
if [[ -f hmm/padlocdb.hmm ]]; then
  echo "padlocdb.hmm already exists. Overwriting..."
  rm hmm/padlocdb.hmm
fi

# Combine hmm profiles
echo 'Compiling database...'
find hmm/ -maxdepth 1 -name "*.hmm" -exec cat {} > hmm/padlocdb.hmm \;
