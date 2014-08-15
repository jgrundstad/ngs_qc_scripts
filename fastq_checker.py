from gzip import GzipFile
from StringIO import StringIO
import argparse
import sys



def opener(filename):
  f = open(filename, 'r')
  if (f.read(2) == '\x1f\x8b'): # are we gzipped?
    f.seek(0)
    return GzipFile(fileobj=f)
  else:
    f.seek(0)
    return f


def run_checks(fastq_gz):

  no_at = 0
  total = 0
  
  gz = opener(fastq_gz)
  for i, line in enumerate(gz):
    total = i
    line = line.strip()
    if i % 4 == 0:
      if not line.startswith('@'):
        no_at += 1
  print "Total seqs: %i\nMissing @: %i" % (total, no_at)

def main():
  p = argparse.ArgumentParser()
  p.add_argument('--fastqgz', '-f', dest='fastq_gz', action='store', required=True, help='fastq.gz file (required)')
  p.add_argument('--at', '-a', action='store_true', required=False, help='check for missing @\'s')
  args = p.parse_args()
 
  if args.at == False:
    print "No checks ordered.  Exiting."
    sys.exit(0)
  else: 
    run_checks(args.fastq_gz)


if __name__ == '__main__':
  main()
