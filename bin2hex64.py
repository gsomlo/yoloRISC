#!/usr/bin/python3
#
# This is free and unencumbered software released into the public domain.
#
# Anyone is free to copy, modify, publish, use, compile, sell, or
# distribute this software, either in source code form or as a compiled
# binary, for any purpose, commercial or non-commercial, and by any
# means.

from sys import argv

binfile = argv[1]
nwords = int(argv[2])

with open(binfile, "rb") as f:
    bindata = f.read()

assert len(bindata) < 8*nwords
assert len(bindata) % 8 == 0

for i in range(nwords):
    if i < len(bindata) // 8:
        w = bindata[8*i : 8*i+8]
        print("%02x%02x%02x%02x%02x%02x%02x%02x" %
            (w[7], w[6], w[5], w[4], w[3], w[2], w[1], w[0]))
    else:
        print("0")
