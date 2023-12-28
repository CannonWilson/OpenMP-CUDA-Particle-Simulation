#!/usr/bin/env zsh
#SBATCH --job-name=KincannonFinalProj
#SBATCH --partition=instruction
#SBATCH --cpus-per-task=1
#SBATCH --output=baseline_sim.out
#SBATCH --error=baseline_sim.err
#SBATCH --mem=20G

# Command used to compile: 
g++ sim.cpp particle_functions.cpp -Wall -O3 -std=c++17 -o sim

# Define number of frames and number of particles
num_frames=10
num_particles=10000

# Run executable:
./sim $num_frames $num_particles
