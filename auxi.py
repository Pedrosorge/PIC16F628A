
def calc(pre,tmr):
    return 1000000/pre/(256-tmr)

i=2
while(i<256):

    for x in range(1,256):
        temp = calc(i,x)
        pri = temp*0.125
        seg = temp*0.250
        ter = temp*0.5

        if(temp == int(temp) and pri == int(pri) and seg == int(seg) and ter == int(ter)):
            print("=-="*5)
            print(f"Pre = {i}")
            print(f"TMR0 = {x}")
            print(f"{temp} tiques/seg")
            print(f"{pri} -> 0.125")
            print(f"{seg} -> 0.250")
            print(f"{ter} -> 0.5")
        
    i*=2
