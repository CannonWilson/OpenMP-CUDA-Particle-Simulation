#include "particle_functions.h"

float BOX_WIDTH = 100.0f;

void print_positions(float* positions, int num_positions, FILE* file_ptr) {
    // Prints out positions for a single frame to a file.
    // Positions for different particles are stored in 1D
    // and are separated by commas like this:
    // x1, y1, z1, x2, y2, z2, . . .
    // Positions for frames are separated by newlines
    int i=0;
    for (; i<num_positions-1; i++) {
        fprintf(file_ptr, "%f,%f,%f,", positions[i*3], positions[i*3+1], positions[i*3+2]);
    }
    i++;
    fprintf(file_ptr, "%f,%f,%f\n", positions[i*3], positions[i*3+1], positions[i*3+2]);
}

void print_densities(float* positions, int num_positions, FILE* file_ptr, int num_regions_per_dim) {
    // Prints out particle densities for a single frame to a file.
    // Densities for different regions are separated by commas like this:
    // density1, density2, density3, . . .
    // Densities for frames are separated by newlines
    
    int num_regions = num_regions_per_dim * num_regions_per_dim * num_regions_per_dim;
    int* region_counts = new int[num_regions]();  // Initialize to zero

    // Loop over each particle and count it toward the correct region
    for (int i = 0; i < num_positions; i += 3) {
        int r_x = static_cast<int>(floor((positions[i] / BOX_WIDTH) * num_regions_per_dim));
        int r_y = static_cast<int>(floor((positions[i + 1] / BOX_WIDTH) * num_regions_per_dim));
        int r_z = static_cast<int>(floor((positions[i + 2] / BOX_WIDTH) * num_regions_per_dim));

        if (0 <= r_x && r_x < num_regions_per_dim &&
            0 <= r_y && r_y < num_regions_per_dim &&
            0 <= r_z && r_z < num_regions_per_dim) {
            int region_index = r_x * num_regions_per_dim * num_regions_per_dim + r_y * num_regions_per_dim + r_z;
            region_counts[region_index]++;
        }
    }

    // Write to output file using the completed list for this frame
    for (int i = 0; i < num_regions - 1; i++) {
        fprintf(file_ptr, "%d,", region_counts[i]);
    }
    fprintf(file_ptr, "%d\n", region_counts[num_regions - 1]);

    delete[] region_counts;
}
