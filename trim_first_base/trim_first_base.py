import sys

count=1

for line in sys.stdin:
  if count % 2 == 0:
    line = line[1:]
  sys.stdout.write(line)
  count += 1
