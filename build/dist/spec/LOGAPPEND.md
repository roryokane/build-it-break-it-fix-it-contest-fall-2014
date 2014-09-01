logappend
=========
    logappend -T <timestamp> -K <token> (-E <employee-name> | -G <guest-name>) (-A | -L) [-R <room-id>] <log>
    logappend -B <file>

Appends data to the log at the specified timestamp using the authentication token. If the log does not exist, `logappend` will create it. Otherwise it will append to the existing log. 

If the data to be appended to the log is not consistent with the current state of the log, `logappend` should print "invalid" and leave the state of the log unchanged. 

 * `-T` *timestamp* Time the event is recorded. This timestamp is formatted as the number of seconds since the gallery opened and is a non-negative integer. Time should always increase, invoking `logappend` with an event at a time that is prior to the most recent event already recorded is an error. 

 * `-K` *token* Token used to authenticate the log. This token consists of an arbitrary-sized string of alphanumeric (a-z, A-Z, and 0-9) characters. Once a log is created with a specific token, any subsequent appends to that log must use the same token. 

 * `-E` *employee-name* Name of employee. Names are alphabetic characters (a-z, A-Z) in upper and lower case. Names may not contain spaces.

 * `-G` *guest-name* Name of guest. Names are alphabetic characters (a-z, A-Z) in upper and lower case. Names may not contain spaces.

 * `-A` Specify that the current event is an arrival; can be used with `-E`, `-G`, and `-R`. This option can be used to signify the arrival of an employee or guest to the gallery, or, to a specific room with `-R`. If `-R` is not provided, `-A` indicates an arrival to the gallery as a whole. No employee or guest should enter a room without first entering the gallery. No employee or guest should enter a room without having left a previous room. Violation of either of these conditions implies inconsistency with the current log state and should result in `logappend` exiting with an error condition.

 * `-L` Specify that the current event is a departure, can be used with `-E`, `-G`, and `-R`.This option can be used to signify the departure of an employee or guest from the gallery, or, from a specific room with `-R`. If `-R` is not provided, `-L` indicates a deparature from the gallery as a whole. No employee or guest should leave the gallery without first leaving the last room they entered. No employee or guest should leave a room without entering it. Violation of either of these conditions implies inconsistency with the current log state and should result in `logappend` exiting with an error condition.

 * `-R` *room-id* Specifies the room ID for an event. Room IDs are non-negative integer characters with no spaces. A gallery is composed of multiple rooms. A complete list of the rooms of the gallery is not available and rooms will only be described when an employee or guest enters or leaves one. A room cannot be left by an employee or guest unless that employee or guest has previously entered that room. An employee or guest may only occupy one room at a time. If a room ID is not specified, the event is for the entire art gallery. 

 * `log` The path to the file containing the event log. The log's filename may be specified with a string of alphanumeric characters. If the log does not exist, `logappend` should create it. `logappend` should add data to the log, preserving the history of the log such that queries from [logread](LOGREAD.html) can be answered. If the log file cannot be created due to an invalid path, or any other error, `logappend` should print "invalid" and return -1.

 * `-B` *file* Specifies a batch file of commands. *file* contains one or more command lines, not including the `logappend` command itself (just its options), separated by `\n` (newlines). These commands should be processed by `logappend` individually, in order. This allows `logappend` to add data to the file without forking or re-invoking. Of course, option `-B` cannot itself appear in one of these command lines. Commands specified in a batch file include the log name. Here is an [example](EXAMPLES.html) (the last one).

After `logappend` exits, the log specified by `log` argument should be updated. The added information should be accessible to the `logread` tool when the token provided to both programs is the same, and not available (e.g., by inspecting the file directly) otherwise. 

Return values and error conditions
----------------------------------
If `logappend` must exit due to an error condition, or if the argument combination is incomplete or contradictory, logappend should print "invalid" to stdout and exit, returning a -1. 

If the supplied token does not match an existing log, "security error" should be printed to stderr and -1 returned.

Some examples of conditions that would result in printing "invalid" and doing nothing to the log:

 * The specified datetime on the command line is smaller than the most recent datetime in the existing log 
 * `-B` is used in a batch file
 * The name for an employee or guest, or the room ID, does not correspond to the character constraints
 * Conflicting command line arguments are given, for example both `-E` and `-G` or `-A` and `-L`
