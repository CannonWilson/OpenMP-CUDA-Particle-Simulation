import matplotlib.pyplot as plt

with open("baseline_sim.out", "r", encoding='utf-8') as f:
    base_time = float(f.read().split(" ")[-1][:-2])

with open("omp_sim.out", "r", encoding='utf-8') as f:
    omp_time = float(f.read().split(" ")[-1][:-2])

with open("gpu_sim.out", "r", encoding='utf-8') as f:
    gpu_time = float(f.read().split(" ")[-1][:-2])


# Create data for the plot
labels = ['Baseline', 'OpenMP', 'GPU']
times = [base_time, omp_time, gpu_time]

# Convert times to log scale
log_times = [max(1e-6, t) for t in times]  # Avoid log(0)
log_times = [round(x, 6) for x in log_times]  # Round for cleaner labels

# Create histogram plot
fig, ax = plt.subplots()
bars = plt.bar(labels, log_times, color=['blue', 'orange', 'green'])
plt.yscale('log')
plt.ylabel('Execution Time (log(ms))')

# Add time values above each bar
for bar, time in zip(bars, log_times):
    yval = bar.get_height()
    plt.text(bar.get_x() + bar.get_width() / 2, yval, f'{time} ms', ha='center', va='bottom')

plt.show()
