#ifndef PARTICLE_FUNCTIONS_H
#define PARTICLE_FUNCTIONS_H

#include <cstdio>
#include <cmath>

void print_positions(float* positions, int num_positions, FILE* file_ptr);

void print_densities(float* positions, int num_positions, FILE* file_ptr, int num_regions_per_dim);

#endif
