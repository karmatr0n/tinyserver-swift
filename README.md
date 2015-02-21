Description
===========

This program runs a small server receiving a string and returns a new one in upcase format. It was designed for academic purposes and to understand how the Unix Sockets work in the Swift language.

Build instructions
=====================

$ xcrun swiftc -sdk $(xcrun --show-sdk-path --sdk macosx) -o tinyserver main.swift socket.swift

Command execution
=================

$ ./tinyserver

Testing
=======

$ telnet localhost 8000

Type something..
