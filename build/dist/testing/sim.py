#!/usr/bin/env python
import os
import sys
import time
import random
import bisect
import base64
import string
import argparse
import itertools
import subprocess
import xml.etree.ElementTree as ET

tk = file('names', 'r')
tk_lines = tk.readlines()
names = [i.strip() for i in tk_lines]

class Person(object):
  def __init__(self, name, isGuest, curRoom=None):
    self.curRoom = curRoom
    self.name = name
    self.isGuest = isGuest
  def __str__(self):
    return self.name

def makePerson():
  isGuest = False
  if random.randrange(0, 9) > 3:
    isGuest = True
  name = ''.join(random.choice(string.ascii_uppercase) for _ in range(12))
  name = random.choice(names)
  names.remove(name)
  return Person(name, isGuest)

def summarize(people, html):
  """
  This should match the spec for -S
  So go over people and make a list of employees, guests, and then 
  a dict mapping rooms to people by integer ID
  """
  s = ""
  rooms = {}
  employees = []
  guests = []
  for p in people:
    if p.isGuest == True:
      guests.append(p.name)
    else:
      employees.append(p.name)
    if p.curRoom != None:
      if rooms.has_key(p.curRoom):
        rooms[p.curRoom].append(p.name)
      else:
        rooms[p.curRoom] = [p.name]
  employees.sort()
  guests.sort()
  room_ids = rooms.keys()
  room_ids.sort()
  s = ""
  if html == True:
    s = "<html><body><table><tr><th>Employee</th><th>Guest</th></tr>"
    s = s + "<tr>\n"
    for (employee,guest) in itertools.izip_longest(employees,guests):
      k = "<tr>"
      if employee != None:
        k = k + "<td>%s</td>" % employee
      else:
        k = k + "<td></td>"
      
      if guest != None:
        k = k + "<td>%s</td>" % guest 
      else:
        k = k + "<td></td>"
      k = k + "</tr>\n"
      s = s + k
    s = s + "</tr></table>"
    s = s + "<table><tr><th>Room ID</th><th>Occupants</th></tr>"
    for i in room_ids:
      k = ""
      r = rooms[i]
      r.sort()
      k = "<tr><td>%d</td>\n" % i
      k = k + "<td>"
      k = k + ",".join(r)
      k = k + "</td></tr>\n" 
      s = s + k
    s = s + "</table></body></html>"
  else:
    emp_str = ",".join(employees)
    gu_str = ",".join(guests)
    s = emp_str + "\n" + gu_str + "\n"
    tmp = []
    for k in room_ids:
      tk = rooms[k]
      tk.sort()
      tmp.append("%d: %s" % (k, ",".join(tk)))
    s = s + "\n".join(tmp) 
  return s

def timespent(name, history):
  n = 0
  timesofar = 0
  entertime = None
  exittime = None
  previouslyinroom = False
  for t in history.keys():
    timesofar = t
    l = history[t]
    if entertime == None:
      #see if name has entered 
      for j in l:
        if j.name == name:
          entertime = t 
    elif exittime == None:
      found = False
      for j in l:
        if j.name == name:
          found = True
      if found == False:
        exittime = t
  if entertime != None and exittime != None:
    n = exittime-entertime
  else:
    n = timesofar-entertime
  return "%d" % n

def roomlist(name, history, html):
  rooms = []
  prevRoom = None
  for t in history.keys():
    l = history[t]
    for i in l:
      if i.name == name:
        if i.curRoom != None:
          if prevRoom != i.curRoom:
            rooms.append("%d" % i.curRoom) 
            prevRoom = i.curRoom
  if html == True:
    s = "<html><body><table><tr><th>Rooms</th></tr>"
    s = s + "".join(["<tr><td>%s</td></tr>\n" % i for i in rooms])
    s = s + "</table></body></html>"
    return s
  else:
    return ",".join(rooms)

def empHistory2(history,a,b,c,d,html):
  times = history.keys()
  ainterval = times[bisect.bisect_left(times,a):bisect.bisect_right(times,b)]
  binterval = times[bisect.bisect_left(times,c):bisect.bisect_right(times,d)]
  amatches = set()
  bmatches = set()
  for t in ainterval:
    l = history[t]
    for i in l:
      if i.isGuest == False:
        amatches.add(i.name)

  for t in binterval:
    l = history[t]
    for i in l:
      if i.isGuest == False:
        bmatches.add(i.name)

  matches = set()
  for t in amatches:
    if t not in bmatches:
      matches.add(t)
  matcheslist = list(matches)
  matcheslist.sort()
  if html == True:
    t = "<html><body><table><tr><th>Employees</th></tr>"
    t = t + "".join(["<tr><td>%s</td></tr>\n" % i for i in matcheslist])
    t = t + "</table></body></html>"
    return t
  else:
    return ",".join(matcheslist)

def empHistory(history, lowerbound, upperbound, html):
  times = history.keys()
  searchtimes = times[bisect.bisect_left(times,lowerbound):bisect.bisect_right(times,upperbound)]
  matches = set()
  for t in searchtimes:
    l = history[t]
    for i in l:
      if i.isGuest == False:
        matches.add(i.name)
  s = list(matches)
  s.sort()
  if html == True:
    t = "<html><body><table><tr><th>Employees</th></tr>"
    t = t + "".join(["<tr><td>%s</td></tr>\n" % i for i in s])
    t = t + "</table></body></html>"
    return t
  else:
    return ",".join(s)

def roomHistory(history, names, html):
  roomsoccupied = {}
  for n in names:
    roomsoccupied[n] = set()
  for t in history.keys():
    l = history[t]
    for n in l:
      if n.curRoom != None and n.name in names:
        roomsoccupied[n.name].add(n.curRoom)
  sets = roomsoccupied.values()
  rooms = set.intersection(*sets)
  roomslist = list(rooms)
  roomslist.sort()
  roomsstrs = [str(i) for i in roomslist]
  if html == True:
    s = "<html><body><table><tr><th>Rooms</th></tr>"
    s = s + "".join(["<tr><td>%s</td></tr>\n" % i for i in roomslist])
    s = s + "</table></body></html>"
    return s
  else:
    return ",".join(roomsstrs)

def makeQuery(secret, logfile, people, history, test, steps, html):
  tst = ""
  if test == "summary":
    if html == True:
      tst = "-K %s -H -S %s" % (secret, logfile),summarize(people,html)
    else:
      tst = "-K %s -S %s" % (secret, logfile),summarize(people,html)
  elif test == "time":
    #get a name from the history of someone who has been in the gallery
    names = set()
    for t in history.keys():
      l = history[t]
      for n in l: names.add((n.name,n.isGuest))
    name,isGuest = random.choice(list(names))
    tgt = "-E"
    if isGuest == True:
      tgt = "-G"
    tst = "-K %s -T %s %s %s" % (secret, tgt, name, logfile),timespent(name,history)
  elif test == "rooms":
    names = set()
    for t in history.keys():
      l = history[t]
      #only add guests that actually go into a room
      for n in l: 
        if n.curRoom != None:
          names.add((n.name,n.isGuest))
    name,isGuest = random.choice(list(names))
    tgt = "-E"
    if isGuest == True:
      tgt = "-G"
    if html == True:
      tst = "-K %s -H -R %s %s %s" % (secret, tgt, name, logfile),roomlist(name,history, html)
    else:
      tst = "-K %s -R %s %s %s" % (secret, tgt, name, logfile),roomlist(name,history, html)
  elif test == "emphistory":
    lowerbound = random.randint(0, steps/2)
    upperbound = random.randint((steps/2)+1, steps)
    if html == True:
      tst = "-K %s -H -A -L %d -U %d %s" % (secret, lowerbound, upperbound, logfile),empHistory(history,lowerbound,upperbound,html)
    else:
      tst = "-K %s -A -L %d -U %d %s" % (secret, lowerbound, upperbound, logfile),empHistory(history,lowerbound,upperbound,html)
  elif test == "roomhistory":
    names = set()
    for t in history.keys():
      l = history[t]
      for n in l: names.add((n.name,n.isGuest))
    if len(names) > 5:
      k = 5
    else:
      k = len(names)
    querynames = random.sample(names, k)
    namelistt = []
    for (name,isGuest) in querynames:
      tgt = "-E"
      if isGuest == True:
        tgt = "-G"
      namelistt.append("%s %s" % (tgt, name)) 
    namelist = " ".join(namelistt)
    if html == True:
      tst = "-K %s -H -I %s %s" % (secret, namelist, logfile),roomHistory(history, [n for (n,i) in querynames], html)
    else:
      tst = "-K %s -I %s %s" % (secret, namelist, logfile),roomHistory(history, [n for (n,i) in querynames], html)
  elif test == "exclusivebounds":
    a = random.randint(0, steps/4)
    b = random.randint((steps/4)+1, steps/2)
    c = random.randint((steps/2)+1, (steps*3)/4)
    d = random.randint(((steps*3)/4)+1, steps)
    if html == True:
      tst = "-K %s -H -B -L %d -U %d -L %d -U %d %s" % (secret, a, b, c, d, logfile),empHistory2(history,a,b,c,d,html)
    else:
      tst = "-K %s -B -L %d -U %d -L %d -U %d %s" % (secret, a, b, c, d, logfile),empHistory2(history,a,b,c,d,html)

  return tst

def doMain(steps, toolpath, out, batch, test, html):
  curstep = 1
  curavg = 0.0
  curtotal = 0.0
  people = []
  secret = ''.join(random.choice(string.ascii_uppercase) for _ in range(8))
  logfile = ''.join(random.choice(string.ascii_uppercase) for _ in range(8))
  cmds = []
  history = {}
  while curstep < steps:
    r = random.randrange(0, 9)
    if (r >= 0 and r < 3) or len(people) == 0:
      #someone enters!
      newPerson = makePerson()
      people.append(newPerson)
      tsr = "-E"
      if newPerson.isGuest == True:
        tsr = "-G"
      cmdlist = ["-T", "%d" % curstep, "-K", "%s" % secret, "%s" % tsr, "%s" % newPerson.name, "-A", "%s" % logfile]
      #cmdlist = ["-T", "%d" % curstep, "%s" % tsr, "%s" % newPerson.name, "-A"]
      cmds.append(cmdlist)
      history[curstep] = [Person(p.name, p.isGuest, p.curRoom) for p in people]
      curstep = curstep + 1
    elif ((r >= 7 and r < 9) and (len(people) != 0)) or len(people) == 20:
      #someone leaves! choose at random
      pidx = random.randrange(0, len(people))
      gonePerson = people[pidx]
      tsr = "-E"
      if gonePerson.isGuest == True:
        tsr = "-G"

      #if they are in a room, they should leave the room
      if gonePerson.curRoom != None:
        cmdlist = ["-T", "%d" % curstep, "-K", "%s" % secret, "%s" % tsr, "%s" % gonePerson.name, "-L", "-R", "%d" % gonePerson.curRoom, "%s" % logfile]
        #cmdlist = ["-T", "%d" % curstep, "%s" % tsr, "%s" % gonePerson.name, "-L", "-R", "%d" % gonePerson.curRoom]
        cmds.append(cmdlist)
        history[curstep] = [Person(p.name, p.isGuest, p.curRoom) for p in people]
        curstep = curstep + 1
      
      people.remove(gonePerson)
      cmdlist = ["-T", "%d" % curstep, "-K", "%s" % secret, "%s" % tsr, "%s" % gonePerson.name, "-L", "%s" % logfile]
      cmds.append(cmdlist)
      history[curstep] = [Person(p.name, p.isGuest, p.curRoom) for p in people]
      curstep = curstep + 1
    elif r >= 3 and r < 7:
      #someone moves! pick someone at random, and a random room for them to move to
      pidx = random.randrange(0, len(people))
      person = people[pidx]
      newRoom = random.randint(0, 20)
      tsr = "-E"
      if person.isGuest == True:
        tsr = "-G"
      if person.curRoom != None:
        cmdlist = ["-T", "%d" % curstep, "-K", "%s" % secret, "%s" % tsr, "%s" % person.name, "-L", "-R", "%d" % person.curRoom, "%s" % logfile]
        cmds.append(cmdlist)
        history[curstep] = [Person(p.name, p.isGuest, p.curRoom) for p in people]
        curstep = curstep + 1

        while newRoom == person.curRoom:
          newRoom = random.randint(0, 20)

      cmdlist = ["-T", "%d" % curstep, "-K", "%s" % secret, "%s" % tsr, "%s" % person.name, "-A", "-R", "%d" % newRoom,"%s" % logfile]
      cmds.append(cmdlist)
      person.curRoom = newRoom
      history[curstep] = [Person(p.name, p.isGuest, p.curRoom) for p in people]
      curstep = curstep + 1
  
  data = ""
  for i in cmds:
    line = " ".join(i)
    data = data + line + "\n"

  query_args,output = makeQuery(secret, logfile, people, history, test, steps, html)

  #make test.xml
  if batch == False:
    f = file(out+".xml", 'w')
    t = ET.Element('test')
    #t.set('logfile', logfile)
    #t.set('secret', secret)
    t.set('type', "correctness")
    xml_cmds = ET.SubElement(t, 'commands')
    #write db-generating stuff
    for i in cmds:
      c = ET.SubElement(xml_cmds, 'command')
      args = ET.SubElement(c, 'args')
      args.text = " ".join(i)
      program = ET.SubElement(c, 'program')
      program.text = 'logappend'
    #write db-query string
    out_cmd = ET.SubElement(xml_cmds, 'command')
    args = ET.SubElement(out_cmd, 'args')
    args.text = query_args
    program = ET.SubElement(out_cmd, 'program')
    program.text = 'logread'
    outpt = ET.SubElement(out_cmd, 'output')
    outpt.text = output
    errpt = ET.SubElement(out_cmd, 'erroutput')
    retcode = ET.SubElement(out_cmd, 'returncode')
    retcode.text = "0"
    f.write(ET.tostring(t))
  else:
    f = file(out+".xml", 'w')
    t = ET.Element('test')
    #t.set('logfile', logfile)
    t.set('type', "correctness")
    fl = ET.SubElement(t, 'inputfile')
    fl.text = base64.b64encode(data)
    fl.set('name', "%s_input" % out)
    xml_cmds = ET.SubElement(t, 'commands')
    xml_cmd = ET.SubElement(xml_cmds, 'command')
    program = ET.SubElement(xml_cmd, 'program')
    program.text = 'logappend'
    args = ET.SubElement(xml_cmd, 'args')
    args.text = '-B %s_input' % out
    out_cmd = ET.SubElement(xml_cmds, 'command')
    program = ET.SubElement(out_cmd, 'program')
    program.text = 'logread'
    query = ET.SubElement(out_cmd, 'args')
    query.text = query_args
    outpt = ET.SubElement(out_cmd, 'output')
    outpt.text = output
    errpt = ET.SubElement(out_cmd, 'erroutput')
    retcode = ET.SubElement(out_cmd, 'returncode')
    retcode.text = "0"
    f.write(ET.tostring(t))

  return 0

if __name__ == "__main__":
  parser = argparse.ArgumentParser(description='Testing tool')
  parser.add_argument('--steps', dest='timesteps', type=int, required=True,
                  help='time steps to run simulation for')
  parser.add_argument('--seed', dest='seed', type=int,
                  help='seed for RNG')
  parser.add_argument('--logappend', dest='logappend', type=str, default="./logappend",
                  help='path to logappend')
  parser.add_argument('--series', dest='series', type=bool, default=False,
                  help='do a series based on steps ')
  parser.add_argument('--out', dest='out', type=str, default="out",
                  help='output base filename')
  parser.add_argument('--batch', dest='batch', type=bool, default=False,
                  help='do batch file')
  parser.add_argument('--test', dest='test', type=str, default="summary",
                  help='test kind summary|time|rooms|emphistory|roomhistory|exclusivebounds')
  parser.add_argument('--html', dest='html', type=bool, default=False,
                  help='do HTML output')

  args = parser.parse_args()

  if args.seed != None:
    random.seed(args.seed)

  if args.series:
    k = args.timesteps
    ts = [k, k*2, k*4, k*10, k*20, k*30, k*50, k*100, k*200, k*250, k*300, k*350, k*600, k*1000]
    for i in ts:
      doMain(i, args.logappend, args.out, args.batch, args.test, args.html)
  else:
    sys.exit(doMain(args.timesteps, args.logappend, args.out, args.batch, args.test, args.html))
