import array
import math
import binascii

size = 16
maxval = 255
hsqrt2 = math.sqrt(2) / 2

table = array.array('d', [0]*size)
table[size-1] = maxval

for i in range(size-1,-1,-1):
    table[i-1] = table[i] * hsqrt2

table[size-1] = maxval

# linearly interpolate
outputsize = 255
inter = array.array('d', [0]*outputsize)
ratiostep = outputsize/size
for i in range(1,outputsize):
    tit = max(int(i/ratiostep),1) 
    diff = table[tit] - table[tit-1]
    ratio = i/size
    ratio -= math.floor(ratio)
    inter[i] = table[tit-1] + diff*ratio
    print(inter[i], ratio, tit, diff)

inter[outputsize-1] = maxval

for i in range(0,outputsize):
    print(int(inter[i]))

# keep half of them and pack to word size
i = 0
while i < outputsize:
    lo = int(inter[i])
    i += 2
    hi = int(inter[i])
    i += 2
    print(binascii.hexlify(memoryview(bytearray([lo,hi]))))
