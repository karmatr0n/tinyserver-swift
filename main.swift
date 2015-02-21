// tinyserver-swift
//
// Created by Alejandro Juárez Robles on 2/20/15.
// Copyright (c) 2015 MonsterLabs. All rights reserved.
//
// This program runs a small server receiving a string and
// returns a new one in upcase format. It was designed for
// academic purposes and to understand how the Unix Socket works
// in the Swift language.
//
// Also, it runs in MacOS, but you do some little tweaksyou can port
// this  code to iOS (take care about the background stuff and the
// home button tap).
//
// Run this program and use the telnet program to test its behaviour
//
// $ telnet localhost 8000
// Type whatever you want

import Foundation

class TinyServer {

  var error: NSErrorPointer
  var listenPort: in_port_t
  var acceptSocket: CInt

  init(port:in_port_t = 8000) {
    error = nil
    listenPort = port
    acceptSocket = -1
  }

  func releaseSocket() {
    Socket.release(acceptSocket)
    acceptSocket = -1
  }

  func printInfo() {
    println("Starting server at localhost \(listenPort)")
  }

  func start() -> Bool {
    self.releaseSocket()

    if let socket = Socket.portListen(port: listenPort, error: error) {
      self.printInfo()
      acceptSocket = socket
      while let socket = Socket.acceptSocket(self.acceptSocket) {

        while let recvString = Socket.read(socket, error: self.error) {

          if recvString.uppercaseString == "QUIT" {
            Socket.writeUTF8(socket, string: "Good bye\r\n")
            Socket.release(socket)
            break
          } else {
            Socket.writeUTF8(socket, string: recvString.uppercaseString)
            Socket.writeUTF8(socket, string: "\r\n")
          }

        }

      }
      self.releaseSocket()
    }
    return false
  }

}

var server = TinyServer(port: 8000)
server.start()


