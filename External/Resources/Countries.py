#!/usr/bin/env python

import csv
lol = list(csv.reader(open('Countries.txt', 'rb'), delimiter='\t'))

print "{"

for item in lol:
    print "    \""+item[1]+"\" : \""+item[0]+"\","

print "}"