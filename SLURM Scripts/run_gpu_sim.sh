#!/usr/bin/env zsh
#SBATCH --job-name=KincannonFinalProj
#SBATCH --partition=instruction
#SBATCH --gres=gpu:1
#SBATCH --output=gpu_sim.out
#SBATCH --error=gpu_sim.err
#SBATCH --mem=20G

# Load CUDA module
module load nvidia/cuda/11.8.0

# Command used to compile: 
nvcc gpu_sim.cu particle_functions.cpp -O3 -std=c++17 -o sim_gpu

# Define number of frames and number of particles
num_frames=10
num_particles=10000

# Run executable:
./sim_gpu $num_frames $num_particles
