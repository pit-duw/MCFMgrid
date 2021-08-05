import sys



with open(sys.argv[1], 'r') as stream:
    lines = stream.readlines()
    lines_new = [i for i in lines if not (i.startswith("0x") or i.startswith("		+--") or i.startswith("m_v[") or i.isspace())]

print("".join(lines_new))