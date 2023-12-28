with open("densities_result.txt", "r") as f:
    line1 = f.read().splitlines()[0]
    line1_arr = line1.split(",")
    print('len of line1: ', len(line1_arr))
    
    sum = 0
    for i in range(0, len(line1_arr)):
        sum += int(line1_arr[i])

    print(f'sum=', sum)