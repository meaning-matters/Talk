#!/usr/bin/env python

import csv
lol = list(csv.reader(open('Map.txt', 'rb'), delimiter=':'))

print "{"

for item in lol:
    print "    \""+item[0]+"\" : "+item[1]+","

print "}"