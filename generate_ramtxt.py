import sys

def str2bin(text):
    for i in range(0, len(text)):
        char = ord(text[i])
        print(f'{char:08b}')

txt = []
txt.append("                ")
txt.append("                ")
txt.append("                ")
txt.append("               #")

with open(f'ram.txt', 'w') as f:
    sys.stdout = f
    for i in range(0,4):
        str2bin(txt[i])