#!/usr/bin/env python
import argparse
import base64
import xml.etree.ElementTree as ET
import HTMLParser

def main(xml):
  t = ET.parse(xml)
  logname = ""
  #get the log file name from the xml
  for (i, k) in t.getroot().items():
    if i == "logfile":
      logname = k
  if len(logname) > 0:
    print "logfile == %s" % logname
  print "Input commands"
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
    parms.append(cmd)
    k = b['args'].split(' ')
    for i in k:
      parms.append(i)
    parms.append("%s" % logname)
    print ' '.join(parms)
    o = b['output']
    if "-H" in b['args']:
      o = HTMLParser.HTMLParser().unescape(o)
    print "stdout == %s" % o
    print "stderr == %s" % b['erroutput']
    print "returncode == %s" % b['returncode']
  print "Input files"
  inputxml = t.findall("inputfile")
  for c in inputxml:
    b = {}
    b['inputfile'] = c.text
    for (i,k) in c.items():
      b[i] = k
    print "filename %s" % b['name']
    dt = base64.b64decode(b['inputfile'])
    print "file data \n%s" % dt

if __name__ == '__main__':
  parser = argparse.ArgumentParser(description='Test executor')
  parser.add_argument('--xml', dest='xml', type=str, default="test.xml", required=True,
                    help='test xml input')
  args = parser.parse_args()
  main(args.xml)
