// Imports
#include <iostream>
#include <cstdlib>
#include <cmath>
#include <random>
#include <chrono>
#include "cuda.h"
#include <cuda_runtime.h>
#include "particle_functions.h"


// Provide some namespace shortcuts for timing
using std::cout;
using std::chrono::high_resolution_clock;
using std::chrono::duration;

const float G = 6.67430;//e-11;  // Gravitational constant
const float particle_mass = 1;
const bool saveDensities = true; // Should the simulation save densities (true) or Positions (false)
const char* FILE_NAME = "gpu_results_12-11.txt";


// CUDA kernel for handling collisions
__global__ void handle_collisions_kernel(float* positions, float* velocities, float* accelerations, int num_particles) {
    int tid = blockIdx.x * blockDim.x + threadIdx.x;

    if (tid < num_particles) {
        // Check and handle collisions for the x dimension
        if (positions[tid * 3] < 0.0f) {
            positions[tid * 3] = 0.0f;
            velocities[tid * 3] = 0.0f;
            accelerations[tid * 3] = 0.0f;
        } else if (positions[tid * 3] > 100.0f) {
            positions[tid * 3] = 100.0f;
            velocities[tid * 3] = 0.0f;
            accelerations[tid * 3] = 0.0f;
        }

        // Check and handle collisions for the y dimension
        if (positions[tid * 3 + 1] < 0.0f) {
            positions[tid * 3 + 1] = 0.0f;
            velocities[tid * 3 + 1] = 0.0f;
            accelerations[tid * 3 + 1] = 0.0f;
        } else if (positions[tid * 3 + 1] > 100.0f) {
            positions[tid * 3 + 1] = 100.0f;
            velocities[tid * 3 + 1] = 0.0f;
            accelerations[tid * 3 + 1] = 0.0f;
        }

        // Check and handle collisions for the z dimension
        if (positions[tid * 3 + 2] < 0.0f) {
            positions[tid * 3 + 2] = 0.0f;
            velocities[tid * 3 + 2] = 0.0f;
            accelerations[tid * 3 + 2] = 0.0f;
        } else if (positions[tid * 3 + 2] > 100.0f) {
            positions[tid * 3 + 2] = 100.0f;
            velocities[tid * 3 + 2] = 0.0f;
            accelerations[tid * 3 + 2] = 0.0f;
        }
    }
}

// CUDA kernel for frame update
__global__ void frame_update_kernel(float* positions, float* velocities, float* accelerations, int num_particles) {
    int tid = blockIdx.x * blockDim.x + threadIdx.x;

    if (tid < num_particles) {
        float acc_x = 0.0f;
        float acc_y = 0.0f;
        float acc_z = 0.0f;

        for (int j = 0; j < num_particles; ++j) {
            if (tid != j) {
                float dx = positions[j * 3 + 0] - positions[tid * 3 + 0];
                float dy = positions[j * 3 + 1] - positions[tid * 3 + 1];
                float dz = positions[j * 3 + 2] - positions[tid * 3 + 2];
                float r = sqrtf(dx * dx + dy * dy + dz * dz);

                if (r > 0 && !std::isnan(r)) {
                    float force = (G * particle_mass * particle_mass) / (r * r);

                    acc_x += force * (dx / r);
                    acc_y += force * (dy / r);
                    acc_z += force * (dz / r);
                }
            }
        }

        // Update accelerations
        accelerations[tid * 3 + 0] = acc_x;
        accelerations[tid * 3 + 1] = acc_y;
        accelerations[tid * 3 + 2] = acc_z;

        // Update velocities and positions
        velocities[tid * 3 + 0] += accelerations[tid * 3 + 0];
        velocities[tid * 3 + 1] += accelerations[tid * 3 + 1];
        velocities[tid * 3 + 2] += accelerations[tid * 3 + 2];

        positions[tid * 3 + 0] += velocities[tid * 3 + 0];
        positions[tid * 3 + 1] += velocities[tid * 3 + 1];
        positions[tid * 3 + 2] += velocities[tid * 3 + 2];
    }
}

// Wrapper function for handling collisions on GPU
void handle_collisions_cuda(float* positions, float* velocities, float* accelerations, int num_particles) {
    int num_threads = 256;
    int num_blocks = (num_particles + num_threads - 1) / num_threads;

    handle_collisions_kernel<<<num_blocks, num_threads>>>(positions, velocities, accelerations, num_particles);
    cudaDeviceSynchronize();  // Ensure the kernel execution is completed before proceeding
}

// Wrapper function for frame update on GPU
void frame_update_cuda(float* positions, float* velocities, float* accelerations, int num_particles) {
    int num_threads = 256;
    int num_blocks = (num_particles + num_threads - 1) / num_threads;

    frame_update_kernel<<<num_blocks, num_threads>>>(positions, velocities, accelerations, num_particles);
    cudaDeviceSynchronize();  // Ensure the kernel execution is completed before proceeding

    // Handle the collisions next
    handle_collisions_cuda(positions, velocities, accelerations, num_particles);
}





// Main
int main(int argc, char* argv[]) {

    // Check len of command-line args
    if (argc != 3) {
        std::cout << "Check # of command-line args.";
        return 1; // fail
    }

    // Read command-line arguments
    int num_frames = atoi(argv[1]);
    int num_particles = atoi(argv[2]);

    // Check command-line args are valid
    if (num_frames < 1 || num_particles < 1) {
        std::cout << "Check values for command line args.";
        return 1; // fail
    }

    // Simulator constants
    int box_width = 100;
    int v_init = 0; // Assume velocity will be initialized to 0 in all 3 directions


    // Other useful vars derived from above constants
    int box_volume = box_width * box_width * box_width;
    int particles_per_dim = static_cast<int>(std::round(std::pow(num_particles, 1.0 / 3.0)));
    float grid_spacing = static_cast<float>(box_width) / particles_per_dim; // Distance between particles in each direction
    
    // Random number setup
    float min = 0, max = static_cast<float>(box_width);
    std::random_device rd;
    std::mt19937 eng(rd());
    std::uniform_real_distribution<float> distr(min, max);


    // Timing setup
    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);
    duration<double, std::milli> duration_sec;
    
    // Files info
    FILE* file_ptr;
    file_ptr = fopen(FILE_NAME, "w");


    // Initialize arrays using CUDA managed memory
    float* positions;
    float* velocities;
    float* accelerations;

    cudaMallocManaged(&positions, num_particles * 3 * sizeof(float));
    cudaMallocManaged(&velocities, num_particles * 3 * sizeof(float));
    cudaMallocManaged(&accelerations, num_particles * 3 * sizeof(float));

    // Populate positions with randomly distributed particles
   for (int i=0; i<num_particles; i++) {
        positions[i*3] = distr(eng);
        positions[i*3 + 1] = distr(eng);
        positions[i*3 + 2] = distr(eng);
   }

    // Start timer
    cudaEventRecord(start);

    // Print out initial positions before running sim
    // if (!saveDensities) {
    //     print_positions(positions, num_particles, file_ptr);
    // }

    // Run the sim
    for (int i=0; i<num_frames-1; i++) {
        frame_update_cuda(positions, velocities, accelerations, num_particles);
        // if (saveDensities) {
        //     print_densities(positions, num_particles, file_ptr, particles_per_dim);
        // }
        // else {
        //     print_positions(positions, num_particles, file_ptr);
        // }
    }

    // Stop timer and print timing result
    cudaEventRecord(stop);
    cudaEventSynchronize(stop);
    float elapsed_time;
    cudaEventElapsedTime(&elapsed_time, start, stop);
    std::cout << "Time taken: " << elapsed_time << "ms";

    // Don't forget to free the allocated memory
    cudaFree(positions);
    cudaFree(velocities);
    cudaFree(accelerations);

    // Close opened file
    fclose(file_ptr);

    return 0;
}