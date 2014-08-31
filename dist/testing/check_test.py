#!/usr/bin/env python
import os
import argparse
import subprocess
import base64
import xml.etree.ElementTree as ET
from difflib import HtmlDiff
import HTMLParser

def get_size(start_path = '.'):
  total_size = 0
  for dirpath, dirnames, filenames in os.walk(start_path):
    for f in filenames:
      fp = os.path.join(dirpath, f)
      total_size += os.path.getsize(fp)
  return total_size

def main(xmlin, prefix, keeplog):
  t = ET.parse(xmlin)
  logname = ""
  secret = ""
  #get the log file name from the xml
  for (i, k) in t.getroot().items():
    if i == "logfile":
      logname = k
    if i == "secret":
      secret = k
  start_size = get_size()
  inputxml = t.findall("inputfile")
  for c in inputxml:
    b = {}
    b['inputfile'] = c.text
    for (i,k) in c.items():
      b[i] = k
    print "filename %s" % b['name']
    dt = base64.b64decode(b['inputfile'])
    print "file data \n%s" % dt
    f = file(b['name'], 'w')
    f.write(dt)
    f.close()
  #run all of the command-commands
  commands = t.findall("commands")[0].findall("command")
  for c in commands:
    b = {}
    b['output'] = ""
    b['erroutput'] = ""
    b['returncode'] = "0"
    for e in c:
      if e.text != None:
        b[e.tag] = e.text
    parms = []
    cmd = "%s" % b['program']
    parms.append("%s/%s" % (prefix, cmd))
    if len(secret) > 0:
      parms.append("-K")
      parms.append("%s" % secret)
    k = b['args'].split(' ')
    for i in k:
      parms.append(i)
    if len(logname) > 0: 
      parms.append("%s" % logname)
    print parms
    proc = subprocess.Popen(parms, stdout=subprocess.PIPE, stderr=subprocess.PIPE) 
    out,err = proc.communicate()
    out = out.rstrip()
    err = err.rstrip()
    expctout = b['output']
    if "-h" in b['args']:
      expctout = HTMLParser.HTMLParser().unescape(expctout)
    expcterr = b['erroutput']
    expctret = int(b['returncode'])
    print "expected out %s got %s" % (expctout,out)
    print "expected err %s got %s" % (expcterr,err)
    print "expected return %d got %d" % (expctret,proc.returncode)
  if keeplog == False and len(logname) > 0:
    os.unlink(logname)

  return 0

if __name__ =='__main__':
  parser = argparse.ArgumentParser(description='Test executor')
  parser.add_argument('--prefix', dest='prefix', type=str, default=".",
                    help='program prefix')
  parser.add_argument('--xml', dest='xml', type=str, default="test.xml", required=True,
                    help='test xml input')
  parser.add_argument('--keep-logfile', dest='keeplog', type=bool, default=False,
                    help='do not auto-erase the log file output')

  args = parser.parse_args()
  main(args.xml, args.prefix, args.keeplog)
