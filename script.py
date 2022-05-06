
# Python program to print all
# prime number in an interval
import time
 
def prime(x, y):
    prime_list = []
    for i in range(x, y):
        if i == 0 or i == 1:
            continue
        else:
            for j in range(2, int(i/2)+1):
                if i % j == 0:
                    break
            else:
                prime_list.append(i)
    return len(prime_list)
 
# Driver program
starting_range = 2
ending_range = 100000
start = time.time()
lst=prime(starting_range, ending_range)
end = time.time()
print("No. of Prime numbers between 2 & 100000 are : ", lst)
print("Time taken for running this script: ", end-start)