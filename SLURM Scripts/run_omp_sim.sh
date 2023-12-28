#!/usr/bin/env zsh
#SBATCH --job-name=KincannonFinalProj
#SBATCH --partition=instruction
#SBATCH --nodes=1 --cpus-per-task=8
#SBATCH --output=omp_sim.out
#SBATCH --error=omp_sim.err
#SBATCH --mem=20G

# Command used to compile: 
g++ omp_sim.cpp particle_functions.cpp -Wall -O3 -std=c++17 -o sim_omp -fopenmp

# Define number of frames and number of particles
num_frames=10
num_particles=10000

# Run executable:
./sim_omp $num_frames $num_particles
