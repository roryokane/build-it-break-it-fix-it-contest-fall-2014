Programming Problem: Secure Log File
===============
Changelog
---------
 * [8/29/14 10:00AM] Clarified that a name only contains the alphabetical characters (a-z, A-Z).

Summary
-----
Players will implement a *secure log* to describe the *state
of an art gallery*: the guests and employees who have entered and left,
and persons that are in rooms. The log will be used by *two
programs*. One program, `logappend`, will append new information to this file,
and the other, `logread`, will read from the file and display the state of the art
gallery according to a given query over the log.  Both programs will
use an authentication token, supplied as a command-line argument, to
authenticate each other; the security model is described in more
detail below.

Programs
--------
Players design the log format and implement both `logappend` and
`logread` to use it.
These programs can be written in any
programming language(s) of the contestants' choice as long as they can
be built and executed on the [Linux VM](VM.html) provided by the
organizers. Each program's description is linked below.

 * The [`logappend`](LOGAPPEND.html) program appends data to a log 
 * The [`logread`](LOGREAD.html) program reads and queries data from the log 

`logread` contains a number of features that are optional.

Examples
--------
Look at the page of [examples](EXAMPLES.html) for examples of using the `logappend` and `logread` tools together. 

Security Model
--------------
The system as a whole must guarantee the privacy and integrity of the log in
the presence of an adversary that does not know the authentication token. This token
is used by both the `logappend` and `logread` tools, specified on the command
line. *Without knowledge of the token* an attacker should *not* be able to:

* Query the logs via `logread` or otherwise learn facts
  about the names of guests, employees, room numbers, or times by
  inspecting the log itself
* Modify the log via `logappend`. 
* Fool `logread` or `logappend` into accepting a bogus file. In
  particular, modifications made to the log by means other than correct use of `logappend` should be detected by (subsequent calls to) `logread` or `logappend` when the correct token is supplied

Build-it Round Submission
----------
Each build-it team should
initialize a git repository on either [github](https://github.com/) or [bitbucket](https://bitbucket.org/) and share it 
with the `bibifi` user on either of those services. Create a directory 
named `build` in the top-level directory of this repository and commit your code into that folder. Your 
submission will be scored after every push to the repository. (Beware making your
repository public, or other contestants might be able to see it!)

To score a submission, an automated system will first invoke `make` in the `build`
directory of your submission. The only requirement on `make` is that it 
must function without internet connectivity, and that it must return within 
ten minutes. 

Once make finishes, `logread` and `logappend` should be executable 
files within the `build` directory. An automated system will invoke them with a 
variety of options and measure their responses. 

Break-it Round and Scoring
----------------------

A separate document describes the [Break-it Round](BREAK.html) activities, and another provides information on [scoring](SCORE.html).
