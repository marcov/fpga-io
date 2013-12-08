infile = open("text.txt")
outfile = open("out.txt", "w")

while True:
    line = infile.readline()

    if (line != ""):
        outfile.write("%02X\n" % int(line))
        print line,
    else:
        break

