"""
This file should take the resulting output file from
the simulation, like results.txt (which will be very
large) and condense it into a smaller text file where
instead of the positions of each individual particle, 
it has the counts of the number of particles in each 
region for a frame/line
"""

# Imports
import math



# External Constants
OUTPUT_FILE_NAME = "densities_result.txt"
INPUT_FILE_NAME = "results.txt"
BOX_WIDTH = 100 # From sim.cpp

# Internal Constants
NUM_REGIONS_PER_DIM = 10


# Other vars based on above constants
out_file = open(OUTPUT_FILE_NAME, "w", encoding="utf-8")
in_file = open(INPUT_FILE_NAME, "r", encoding="utf-8")
in_file_txt = in_file.read()
total_num_regions = NUM_REGIONS_PER_DIM**3

# Loop over each line (frame) of input file
for line in in_file_txt.splitlines():

    # Create a 3D list initialized to all 0's to track counts of particles in each region
    region_counts = [[[0 for _ in range(NUM_REGIONS_PER_DIM)] 
                      for _ in range(NUM_REGIONS_PER_DIM)] 
                      for _ in range(NUM_REGIONS_PER_DIM)]
    
    # Loop over each particle and count it toward the correct region
    frame_positions = line.split(",")
    for idx in range(0, len(frame_positions), 3):
        r_x = math.floor((float(frame_positions[idx]) / BOX_WIDTH) * NUM_REGIONS_PER_DIM)
        r_y = math.floor((float(frame_positions[idx+1]) / BOX_WIDTH) * NUM_REGIONS_PER_DIM)
        r_z = math.floor((float(frame_positions[idx+2]) / BOX_WIDTH) * NUM_REGIONS_PER_DIM)

        if (0 <= r_x < NUM_REGIONS_PER_DIM) and \
            (0 <= r_y < NUM_REGIONS_PER_DIM) and \
            (0 <= r_z < NUM_REGIONS_PER_DIM):
            region_counts[r_x][r_y][r_z] += 1

    # Write to output file using the completed list for this frame
    for i_x in range(NUM_REGIONS_PER_DIM):
        for i_y in range(NUM_REGIONS_PER_DIM):
            for i_z in range(NUM_REGIONS_PER_DIM):
                out_file.write(str(region_counts[i_x][i_y][i_z]))
                if (i_x * i_y * i_z < (NUM_REGIONS_PER_DIM-1)**3):
                    out_file.write(",")
    out_file.write("\n") # Separate frames with newlines, as in input file


# Cleanup
out_file.close()
in_file.close()
