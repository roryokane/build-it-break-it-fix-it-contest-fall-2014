# Build It Break It Fix It contest entry, Fall 2014
## `logappend` and `logread` for a gallery

This was the entry of Team “Rory” into the Fall 2014 [Build It Break It Fix It contest](https://www.builditbreakit.org/). In the Build It phase, my team (consisting of only me) was challenged to build a program matching the specification. The program had to be secure in the given way. You can read the specification in [`build/dist/spec`](https://github.com/roryokane/build-it-break-it-fix-it-contest-fall-2014/tree/master/build/dist/spec) or [on the contest website](https://www.builditbreakit.org/static/doc/f2014/spec/SPEC.html), or read the summary below.

The spec describes that we have to write two programs, `logappend` and `logread`, that interact with a secure log file. The log file lists the movements of people moving through a gallery, such as “employee Jill exited room #4 at time 52”. `logappend` is for adding entries to the log, either one by one or from a batch file. `logread` must support various flags for querying the log in certain ways, like printing out who is in each room or printing out the total time spent in the gallery by a given person. Some flags for `logread` are option and result in bonus points.

For security, the log file must be readable only by the gallery owner, who passes an authentication token in on the command-line. Adversaries who don’t know the token must not be able to read the details of log, and the gallery owner should see an error if somebody has tampered with the log. I used two-way encryption and checksumming to accomplish this.

## Status

**Incomplete**. The Build It round lasted three days (72 hours, from August 28 to August 31). I finished much of the program, including all of the security features, and wrote modules that would ease development of further parts. But I did not finish two required features, `logappend -B` and `logread -R`, in time. I also did not finish arranging my project and its build system so that the automatic contest submission system could actually see my submission.

## Security

The spec said this about the security model of the programs:

> The system as a whole must guarantee the privacy and integrity of the log in the presence of an adversary that does not know the authentication token. This token is used by both the `logappend` and `logread` tools, specified on the command line. *Without knowledge of the token* an attacker should *not* be able to:
> 
> * Query the logs via `logread` or otherwise learn facts about the names of guests, employees, room numbers, or times by inspecting the log itself
> * Modify the log via `logappend`.
> * Fool `logread` or `logappend` into accepting a bogus file. In particular, modifications made to the log by means other than correct use of `logappend` should be detected by (subsequent calls to) `logread` or `logappend` when the correct token is supplied

The security was far easier to implement than the rest of the program, even though this contest is about security. I encapsulated all the security in a `SecureFile` module, which provides `safe_write` and `safe_read` methods that satisfy all of the security requirements. Saving a file does only three things:

* The file is reversibly encrypted with AES-128 (using the OpenSSL library). For a key, I use the authentication token, stretched using PKCS#5 (PBKDF2 with a SHA1-based HMAC).The IV is stored in plaintext inside the file, alongside the cipher text.
* Successful decrypted data contains both the actual data and a SHA256 checksum. My programs check the data against the checksum to make sure the file has not been tampered with. The checksum itself cannot be tampered with usefully unless the adversary already knows how to decrypt the file.
* The data itself is simply a Ruby object, serialized using `Marshal`. I chose `Marshal` over JSON for the slight security-through-obscurity feature, to slow down breakers during the breaker phase. Marshal’s code injection possibilities are not a problem, since the adversary is already given my program’s full source code (inside the executable), so they could just edit the program themself if they wanted to.

The only weakness I know of is that I cannot reliably distinguish between a maliciously edited file (“integrity violation”) and an incorrect authentication token (“security error”). The spec is vague on whether an incorrect error message is a bug or not. Adding a salted plain-text checksum would help in some cases but would ultimately be just security through obscurity. Thankfully, this weakness does not actually leak any information. No matter which error message is outputted, the adversary cannot read the file, and if a legitimate user using the correct key gets a “security error”, they would understand that the file was tampered with.

## Language and build system

I chose Ruby as my programming language, because I was most experienced with it and could implement features as quickly as possible within the time limit.

After I read that we would have to produce a single-file executable that could be executed with Python’s `Popen`, I thought I would have to switch to a language that produced native binaries. Ruby would not work, because I could find no reliable tools for compiling Ruby to a binary. I investigated the Go language, but found that it is more low-level than I am used to – for example, it requires you to create your own byte buffers in order to read from standard input. Thankfully, with experimentation, I discovered that I could still use Ruby, by simply including a hashbang line `#!/usr/bin/env ruby` at the top of the file, and making the file executable with `chmod +x`.

The spec required that we use a Makefile:

> To score a submission, an automated system will first invoke `make` in the `build` directory of your submission. The only requirement on `make` is that it must function without internet connectivity, and that it must return within ten minutes.
> 
> Once make finishes, `logread` and `logappend` should be executable files within the `build` directory. An automated system will invoke them with a variety of options and measure their responses. 

Here is [my Makefile]. It builds `logappend` and `logread` out of three files: [`header.rb`], [`logappend-body.rb`], and [`logread-body.rb`]. The header is concatenated to the appropriate file to make the final executable. I split the files in this way because the executables had to be single, standalone files. Thus I could not use `require_relative`, because I would have to manually edit my `Makefile` to match those dependencies.

I could not use `require` either – I was prevented from easily using third-party libraries. To use third-party dependencies, I would have had to change my Makefile to vendor the source code of all included libraries, and copy that source code into my binary. Thankfully, the standard library proved to be basically enough for my needs.

[my Makefile]: https://github.com/roryokane/build-it-break-it-fix-it-contest-fall-2014/blob/master/build/Makefile
[`header.rb`]: https://github.com/roryokane/build-it-break-it-fix-it-contest-fall-2014/blob/master/build/src/header.rb
[`logappend-body.rb`]: https://github.com/roryokane/build-it-break-it-fix-it-contest-fall-2014/blob/master/build/src/logappend-body.rb
[`logread-body.rb`]: https://github.com/roryokane/build-it-break-it-fix-it-contest-fall-2014/blob/master/build/src/logread-body.rb

## Options parsing

I rolled my own options parsing, because the spec required that my program support multiple identical flags in some cases, and no Ruby options-parsing library supports that. The flags that require multiple identical flags are `logread -B`, which require two `-L` `-U`s, and `logread -I`, which require arbitrarily many `-E`s and `-G`s.

I did not abstract the options parsing as much as I could have. When I considered it, I decided that it would take up too much time at that point. The following features could have been abstracted:

* creating and building an `options` `Hash`
* if the flag has an argument, automatically reading its argument
* automatically raising an error if an argument for a flag is missing
* automatically validating an argument against a given regex
* automatically storing either `true` or the argument value in the `options` `Hash`

## What I learned from this project

### Skills and domains

* I learned more about what is needed to save a file securely. I learned that a password cannot be used as a key for AES – it must be passed through a key-stretching function like PBKDF2 first.
* Ruby is not set up for completely immutable data structures. Ruby does not provide methods for changing a `Hash` without modifying the original. So just use a mutable one and add `!` to the end of the names of relevant methods.
* I relearned the syntax for certain features of `make` and Makefiles, like `.PHONY`. I wrote a summary of the features I learned about in a file on my computer. I will be able to use `make` more easily next time by referencing it.
* I used a mix of plain data structures and objects: log events were Hashes, and gallery states were `GalleryState` objects. I did not use those objects in code enough to be sure whether they are the most efficient organization, but it worked decently at least. I have more experience with that style, so I will be able to compare it better to other approaches that I take on future projects.

### Mistakes

* Don’t take too many breaks near the end, or you won’t have enough time.
* If submission to a third-party site isn’t working, reread *all* the relevant documentation and make sure you have set everything up like it describes.
* My time estimation was about 50% too low. On the last day, I expected to be able to finish the program in the 5 hours I worked on it. But now I think that I would now need another 5 hours to completely finish the program, including the optional features. I estimated 5 hours for a 10-hour task.
