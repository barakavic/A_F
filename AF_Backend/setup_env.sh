#!/bin/bash
# setup_env.sh

# 1. Activate the venv from the home directory
source ~/ascentfin_venv/bin/activate

# 2. Set the PYTHONPATH to the current directory (AF_Backend)
export PYTHONPATH=$PYTHONPATH:$(pwd)

echo "Ascent Fin Environment Activated!"
echo "PYTHONPATH set to: $PYTHONPATH"
