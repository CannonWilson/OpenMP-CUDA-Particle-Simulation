with open("results.txt", "r") as f:
    line1 = f.read().splitlines()[0]
    line1_arr = line1.split(",")
    print('len of line1: ', len(line1_arr))
    
    sum = 0
    for i in range(0, len(line1_arr), 3):
        pos_x = float(line1_arr[i])
        pos_y = float(line1_arr[i+1])
        pos_z = float(line1_arr[i+2])

        if (0 <= pos_x <= 100) and (0 <= pos_y <= 100) and (0 <= pos_z <= 100):
            sum+=1

    print(f'sum=', sum)