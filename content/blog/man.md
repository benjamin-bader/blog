+++
date = "2017-10-06T20:28:21-08:00"
draft = true
title = "Things I Forget About man pages"
tags = [ "code", "man", "tips" ]
slug = "things-i-forget-about-man-pages"
+++

`man` is the interactive documentation system on UNIX-like systems.  Most of the time, `man <program>` will give you all you need to know about some command present on the current system.  You know generally what `lsof` does, but don't remember know to find the process listening to port 8080?  `man lsof` will tell you that, and much more besides.  It knows about nearly every command-line program on your computer, and is happy to tell you.

It can inform about more than just command-line programs, but I always forget how `man` works beyond the basics.  Here, then, is my own personal refresher!

#### TL;DR:

- `man` has articles for most commandline programs, shell builtins, C standard library functions, and more
- `man <topic>` for documentation of `<topic>`
- `man` is divided into numbered sections, and one topic name could map to multiple sections
- by default, `man <topic>` shows the first article it finds named `<topic>`, which isn't always what you are looking for
- `man <section #> <topic>` if you know what section you want
- `man -a <topic>` to view articles named `<topic>` from all sections, one after the other
- `apropos <keyword>` to search man pages for `<keyword>`

### What is `man`?

`man` is the system manual, containing detailed documentation on just about every aspect of its operation.  Of course, `man` wouldn't be a proper UNIX program if it couldn't be used recursively.  `man man` will give you exhaustive detail about itself.  It's a lot to take in, so here are what I consider to be the salient details.

#### What's It Do, Again?

When curious about a program or a stdlib function, type `man <name-of-curio>`.  If there's a manual page for the curio, it will be displayed in a "pager", usually a program like `less`, `more`, or similar.  Use the arrow keys to scroll around and read.

Manual pages mostly follow a conventional organization.  Like a good news article, they lead with the most important information, like the name of the program and the options it takes, with details following later.  Articles will typically have some of the following:

- Name: The name of the program, and a sentence or two about what it does
- Synopsis: An example of how to invoke the program, with required and optional parameters listed.  If a program has more than one major mode of operation, there will usually be additional synopses.
- Description: A paragraph or more of text describing what the program does and how to use it in its most common usages.

Pages about C functions will have their parameters and return values documented, too.  Very helpful!

#### Sections

Manual pages are organized by numbered "sections"; the full name of a manual page includes the section, in paranthesis.  `read(2)`, then, is the article `read` in section `2`.  The eight sections are:

```
1. General commands (`cat`, `ls`, etc)
2. Syscalls (OS programming primitives like `read`, `write`, etc)
3. Library functions (C standard library)
4. Special files
5. File formats
6. Games (I've never used this one)
7. Miscellanea (ditto)
8. "System administration commands and daemons"
```

When you type `man <thing>`, the program will display the first matching article it finds.  This is usually what you want, but it won't always be!  There might be multiple articles with the same name, but in different sections.  This can be a problem if, for example, you want to know about the `read` syscall - if you type `man read`, you'll usually get an article about the shell builtin instead!

**Type `man 2 read` to see the `read` syscall page**.  THIS is the thing I always forget!

Also, on at least some versions of `man`, you can use the `-a` option to retrieve _all_ matching entries, one after the other.

### `apropos`

If `man` is the library of documentation, then `apropos` is the reference librarian.  If you give it some keyword that you're interested in, but aren't sure where to find more info, `apropos` will find all the things in the `whatis` database that reference that keyword.  Its output can be overbroad for common terms like `read`, but for more esoteric topics (e.g. "Authorization" on macOS), it can find some unexpectedly helpful documentation.

As far as I can tell, on macOS, `apropos` is present and just works.  I understand that on some systems, one needs to run `makewhatis` _first_, to generate the database that `apropos` will search.


### `fin`

That's it, for now.

