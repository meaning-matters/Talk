#!/usr/bin/env python

# Source is http://www.mcc-mnc.com

import csv
lol = list(csv.reader(open('CountryCodes.txt', 'rb'), delimiter='\t'))

print "["

for item in lol:
    print "    {"
    print "        \"mcc\"  : \""+item[0]+"\","
    print "        \"mnc\"  : \""+item[1]+"\","
    print "        \"iso\"  : \""+item[2].upper()+"\","
    print "        \"code\" : \""+item[4]+"\""
    print "    },"
 
print "]"