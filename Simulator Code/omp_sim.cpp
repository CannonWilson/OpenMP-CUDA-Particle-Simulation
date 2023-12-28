// Imports
#include <iostream>
#include <cstdlib>
#include <cmath>
#include <random>
#include <chrono>
#include "omp.h"
#include "particle_functions.h"


// Provide some namespace shortcuts for timing
using std::cout;
using std::chrono::high_resolution_clock;
using std::chrono::duration;

const float G = 6.67430;//e-11;  // Gravitational constant
const float particle_mass = 1;
const bool saveDensities = true; // Should the simulation save densities (true) or Positions (false)
const char* FILE_NAME = "omp_results_12-11.txt";


void handle_collisions(float* positions, float* velocities, float* accelerations, int num_particles) {
    #pragma omp parallel for
    for (int i = 0; i < num_particles; ++i) {
        // Check if the particle will collide with the box in the x dimension
        if (positions[i * 3] < 0.0f) {
            positions[i * 3] = 0.0f;
            velocities[i * 3] = 0.0f;
            accelerations[i * 3] = 0.0f;
        } else if (positions[i * 3] > 100.0f) {
            positions[i * 3] = 100.0f;
            velocities[i * 3] = 0.0f;
            accelerations[i * 3] = 0.0f;
        }

        // Check if the particle will collide with the box in the y dimension
        if (positions[i * 3 + 1] < 0.0f) {
            positions[i * 3 + 1] = 0.0f;
            velocities[i * 3 + 1] = 0.0f;
            accelerations[i * 3 + 1] = 0.0f;
        } else if (positions[i * 3 + 1] > 100.0f) {
            positions[i * 3 + 1] = 100.0f;
            velocities[i * 3 + 1] = 0.0f;
            accelerations[i * 3 + 1] = 0.0f;
        }

        // Check if the particle will collide with the box in the z dimension
        if (positions[i * 3 + 2] < 0.0f) {
            positions[i * 3 + 2] = 0.0f;
            velocities[i * 3 + 2] = 0.0f;
            accelerations[i * 3 + 2] = 0.0f;
        } else if (positions[i * 3 + 2] > 100.0f) {
            positions[i * 3 + 2] = 100.0f;
            velocities[i * 3 + 2] = 0.0f;
            accelerations[i * 3 + 2] = 0.0f;
        }
    }
}


void frame_update(float* positions, float* velocities, float* accelerations, int num_particles) {
    // Update accelerations
    #pragma omp parallel for
    for (int i = 0; i < num_particles; ++i) {
        float acc_x = 0.0f;
        float acc_y = 0.0f;
        float acc_z = 0.0f;

        #pragma omp parallel for reduction(+:acc_x, acc_y, acc_z)
        for (int j = 0; j < num_particles; ++j) {
            if (i != j) {
                float dx = positions[j * 3 + 0] - positions[i * 3 + 0];
                float dy = positions[j * 3 + 1] - positions[i * 3 + 1];
                float dz = positions[j * 3 + 2] - positions[i * 3 + 2];
                float r = std::sqrt(dx * dx + dy * dy + dz * dz);

                if (r > 0 && !std::isnan(r)) {
                    float force = (G * particle_mass * particle_mass) / (r * r);

                    acc_x += force * (dx / r);
                    acc_y += force * (dy / r);
                    acc_z += force * (dz / r);
                }
            }
        }

        accelerations[i * 3 + 0] = acc_x;
        accelerations[i * 3 + 1] = acc_y;
        accelerations[i * 3 + 2] = acc_z;
    }

    // Update velocities and positions
    #pragma omp parallel for
    for (int i = 0; i < num_particles; ++i) {
        velocities[i * 3 + 0] += accelerations[i * 3 + 0];
        velocities[i * 3 + 1] += accelerations[i * 3 + 1];
        velocities[i * 3 + 2] += accelerations[i * 3 + 2];

        positions[i * 3 + 0] += velocities[i * 3 + 0];
        positions[i * 3 + 1] += velocities[i * 3 + 1];
        positions[i * 3 + 2] += velocities[i * 3 + 2];
    }

    // Assuming handle_collisions is already parallelized
    handle_collisions(positions, velocities, accelerations, num_particles);
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
    high_resolution_clock::time_point start;
    high_resolution_clock::time_point end;
    duration<double, std::milli> duration_sec;
    
    // Files info
    FILE* file_ptr;
    file_ptr = fopen(FILE_NAME, "w");


    // Initialize arrays (1d arrays like x,y,z for each component of quantity measured)
    float* positions = new float[num_particles * 3];
    float* velocities = new float[num_particles * 3];
    float* accelerations = new float[num_particles * 3];

    // Populate positions with randomly distributed particles
   for (int i=0; i<num_particles; i++) {
        positions[i*3] = distr(eng);
        positions[i*3 + 1] = distr(eng);
        positions[i*3 + 2] = distr(eng);
   }

    // Start timer
    start = high_resolution_clock::now();

    // Print out initial positions before running sim
    // if (!saveDensities) {
    //     print_positions(positions, num_particles, file_ptr);
    // }

    // Run the sim
    for (int i=0; i<num_frames-1; i++) {
        frame_update(positions, velocities, accelerations, num_particles);
        // if (saveDensities) {
        //     print_densities(positions, num_particles, file_ptr, particles_per_dim);
        // }
        // else {
        //     print_positions(positions, num_particles, file_ptr);
        // }
    }

    // Stop timer and print timing result
    end = high_resolution_clock::now();
    duration_sec = std::chrono::duration_cast<duration<double, std::milli> >(end - start);
    std::cout << "Time taken: " << duration_sec.count() << "ms";

    // Don't forget to free the allocated memory
    delete[] positions;
    delete[] velocities;
    delete[] accelerations;

    // Close opened file
    fclose(file_ptr);

    return 0;
}