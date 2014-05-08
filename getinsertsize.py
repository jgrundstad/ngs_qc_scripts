#!/usr/bin/env python
'''
Automatically estimate insert size of the paired-end reads for a given SAM/BAM file.
Usage: getinsertsize.py <SAM file> or samtools view <BAM file> | getinsertsize.py -
Author: Wei Li
'''


from __future__ import print_function
import sys;
import pydoc;
import os;
import re;
import fileinput;
import math;
import argparse;

parser=argparse.ArgumentParser(description='Automatically estimate the insert size of the paired-end reads for a given SAM/BAM file.');
parser.add_argument('SAMFILE',type=argparse.FileType('r'),help='Input SAM file (use - from standard input)');
parser.add_argument('--span-distribution-file','-s',type=argparse.FileType('w'),help='Write the distribution of the paired-end read span into a text file with name SPAN_DISTRIBUTION_FILE. This text file is tab-delimited, each line containing two numbers: the span and the number of such paired-end reads.');
parser.add_argument('--read-distribution-file','-r',type=argparse.FileType('w'),help='Write the distribution of the paired-end read length into a text file with name READ_DISTRIBUTION_FILE. This text file is tab-delimited, each line containing two numbers: the read length and the number of such paired-end reads.');

args=parser.parse_args();

plrdlen={};
plrdspan={};

def getmeanval(dic,maxbound=-1):
  nsum=0;  n=0;
  for (k,v) in dic.items():
    if maxbound!=-1 and k>maxbound:
      continue;
    nsum=nsum+k*v;
    n=n+v;
  meanv=nsum*1.0/n;
  nsum=0; n=0;
  for (k,v) in dic.items():
    if maxbound!=-1 and k>maxbound:
      continue;
    nsum=nsum+(k-meanv)*(k-meanv)*v;
    n=n+v;
  varv=math.sqrt(nsum*1.0/(n-1));
  return (meanv,varv);

objmrl=re.compile('([0-9]+)M$');
objmtj=re.compile('NH:i:(\d+)');

nline=0;
imperfect=0; # CIGAR string must end with an M for perfect match, no in/del, etc
mate_not_paired=0  # pair either on other chrom, or negative distance
list_of_lengths=[]
for lines in args.SAMFILE:
  field=lines.strip().split();
  nline=nline+1;
  if nline%1000000==0:
    print(str(nline/1000000)+'M...',file=sys.stderr);
  if len(field)<12:
    continue;
  try:
    mrl=objmrl.match(field[5]);
    if mrl==None: # ignore non-perfect reads
      imperfect=imperfect+1
      continue;
    readlen=int(mrl.group(1));
    if readlen in plrdlen.keys():
      plrdlen[readlen]=plrdlen[readlen]+1;
    else:
      plrdlen[readlen]=1;
    if field[6]!='=':
      mate_not_paried=mate_not_paired+1
      continue;
    dist=int(field[8]);
    if dist<=0: # ignore neg dist
      mate_not_paired=mate_not_paired+1
      continue;
    mtj=objmtj.search(lines);
    # if mtj==None:
    #   continue;
    # if int(mtj.group(1))!=1:
    #   continue;
    #print(field[0]+' '+str(dist));
    if dist in plrdspan.keys():
      plrdspan[dist]=plrdspan[dist]+1;
      list_of_lengths.append(dist)
    else:
      plrdspan[dist]=1;
      list_of_lengths.append(dist)
  except ValueError:
    continue;

#print(str(plrdlen));
#print(str(plrdspan));

sorted_list = sorted(list_of_lengths)
median_len = 0
if len(sorted_list) % 2 == 0:
    median_len = sorted_list[(len(sorted_list)/2)-1]
else:
    median_len = sorted_list[int((len(sorted_list)+0.5)/2)]

# get the maximum value
readlenval=getmeanval(plrdlen);
imp_pct = float(imperfect)/float(nline) * 100
mnp_pct = float(mate_not_paired)/float(nline) * 100
print('Total reads insprected: %d\nImperfect matches: %d (%.4f %%)\nMate not paired: %d (%.4f %%)' % (nline,imperfect,imp_pct,mate_not_paired,mnp_pct))
print('Read length: mean '+str(readlenval[0])+', STD='+str(readlenval[1]));
# print('Possible read lengths and their counts:');
# print(str(plrdlen));

if args.span_distribution_file is not None:
  for k in sorted(plrdspan.keys()):
    print(str(k)+'\t'+str(plrdspan[k]),file=args.span_distribution_file);

if args.read_distribution_file is not None:
  for k in sorted(plrdlen.keys()):
    print(str(k)+'\t'+str(plrdlen[k]),file=args.read_distribution_file);


if len(plrdspan)==0:
  print('No qualified paired-end reads found. Are they single-end reads?');
else:
  maxv=max(plrdspan,key=plrdspan.get);
  spanval=getmeanval(plrdspan,maxbound=maxv*3);
  print('Read span: median '+str(median_len)+', mean '+str(spanval[0])+', STD='+str(spanval[1]));
  # print('maxv:'+str(maxv));

