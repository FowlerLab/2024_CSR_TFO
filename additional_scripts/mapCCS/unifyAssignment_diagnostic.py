#!/usr/bin/env python

"""

:Author: Martin Kircher
:Contact: mkircher@uw.edu
:Date: *01.03.2016
"""

import sys, os
import gzip
from optparse import OptionParser
from collections import defaultdict

parser = OptionParser()
(options, args) = parser.parse_args()

def mean(numbers):
  if len(numbers) > 0:
    return sum(numbers)/float(len(numbers))
  else:
    return 0

barcodes = defaultdict(list)

for filename in args:
  if os.path.exists(filename):
    if filename.endswith(".gz"):
      infile = gzip.open(filename)
    else:
      infile = open(filename)
    for line in infile:
      fields = line.split()
      if len(fields) == 3:
        mQual = mean(map(lambda x:ord(x)-33,fields[2]))
        barcodes[fields[0]].append((fields[1],mQual))
    infile.close()

countConsensus = 0
countTotal = 0
count50 = 0
countQual = 0
for barcode,observations in sorted(barcodes.iteritems()):
  countTotal += 1
  freq = defaultdict(int)
  for seq,qual in observations:
    freq[seq]+=1
  res = map(lambda (x,y):(y,x),freq.iteritems())
  res.sort()
#  for pair in res[-5:]:
#    sys.stdout.write("%s\t%s\t"%(pair[0], len(pair[1]))) #print count, len(seq)
#  sys.stdout.write("\n")
  if len(res) == 1 : countConsensus += 1
  elif 0.5 < res[-1][0]/float(len(observations)) < 1:
    #    sys.stdout.write("%s\t%s\n"%(barcode,res[-1][1])) #commented out
    count50 += 1
  else:
    res = map(lambda (x,y):(y,x),observations) #todo print these too! with seq lengthx
    res.sort()
    countQual += 1
#    for pair in res[-5:]:
#      sys.stdout.write("%s\t%s\t"%(pair[0], len(pair[1]))) #print qual, len(seq)
#    sys.stdout.write("\n")
#    sys.stdout.write("%s\t%s\n"%(barcode,res[-1][1])) #commented out

print "total BC: " + str(countTotal)
print "consensus BC: " + str(countConsensus)
print "50% BC: " + str(count50)
print "qual assigned BC: " + str(countQual)
