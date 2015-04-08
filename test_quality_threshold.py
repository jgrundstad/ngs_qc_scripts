import sys
import re
import argparse

p = argparse.ArgumentParser()
p.add_argument('--threshold', '-t', dest='threshold', action='store', required=True, help='Illumina q score, e.g. "i"')
p.add_argument('--filename', '-f', dest='infile_name', action='store', required=True, help='String to hold name of file, likely passed in via xargs')
args = p.parse_args()

line_counter = 1

if not sys.stdin.isatty():
  for line in sys.stdin:
    line = line.strip()
    if line_counter % 4 == 0:
      for char in list(line):
        #print "char: %i  threshold: %i" % (ord(char), _THRESHOLD)

        if ord(char) >= ord(args.threshold):
          print(args.infile_name)
          sys.exit()
        
    line_counter = line_counter + 1

print "%s below threshold: %s" % (args.infile_name, args.threshold)

