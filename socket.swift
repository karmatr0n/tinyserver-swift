//
//  socket.swift

//
//  Created by Alejandro Juárez Robles on 2/21/15.
//  Copyright (c) 2015 MonsterLabs. All rights reserved.
//

import Foundation

struct Socket {

  static func portListen(port: in_port_t = 8080, error:NSErrorPointer = nil) -> CInt? {
    let s = socket(AF_INET, SOCK_STREAM, 0)
    if ( s == -1 ) {
      if error != nil { error.memory = errorMsg("socket(...) failed.") }
      return nil
    }
    var value: Int32 = 1;
    if ( setsockopt(s, SOL_SOCKET, SO_REUSEADDR, &value, socklen_t(sizeof(Int32))) == -1 ) {
      release(s)
      if error != nil { error.memory = errorMsg("setsockopt(...) failed.") }
      return nil
    }

    var addr = sockaddr_in(sin_len: __uint8_t(sizeof(sockaddr_in)), sin_family: sa_family_t(AF_INET),
      sin_port: port_htons(port), sin_addr: in_addr(s_addr: inet_addr("0.0.0.0")), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))

    var sock_addr = sockaddr(sa_len: 0, sa_family: 0, sa_data: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0))

    memcpy(&sock_addr, &addr, UInt(sizeof(sockaddr_in)))
    if ( bind(s, &sock_addr, socklen_t(sizeof(sockaddr_in))) == -1 ) {
      release(s)
      if error != nil { error.memory = errorMsg("bind(...) failed.") }
      return nil
    }
    if ( listen(s, 128) == -1 ) {
      release(s)
      if error != nil { error.memory = errorMsg("listen(...) failed.") }
      return nil
    }
    return s
  }

  static func errorMsg(reason: String) -> NSError {
    let errorCode = errno
    if let errorText = String.fromCString(UnsafePointer(strerror(errorCode))) {
      return NSError(domain: "Socket", code: Int(errorCode),
        userInfo: [NSLocalizedFailureReasonErrorKey: reason, NSLocalizedDescriptionKey: errorText])
    }
    return NSError(domain: "Socket", code: Int(errorCode), userInfo: nil)
  }

  static func writeUTF8(socket: CInt, string: String, error: NSErrorPointer = nil) -> Bool {
    if let nsdata = string.dataUsingEncoding(NSUTF8StringEncoding) {
      writeData(socket, data: nsdata, error: error)
    }
    return true
  }

  static func writeASCII(socket: CInt, string: String, error: NSErrorPointer = nil) -> Bool {
    if let nsdata = string.dataUsingEncoding(NSASCIIStringEncoding) {
      writeData(socket, data: nsdata, error: error)
    }
    return true
  }

  static func writeData(socket: CInt, data: NSData, error:NSErrorPointer = nil) -> Bool {
    var sent = 0
    let unsafePointer = UnsafePointer<UInt8>(data.bytes)
    while ( sent < data.length ) {
      let s = write(socket, unsafePointer + sent, UInt(data.length - sent))
      if ( s <= 0 ) {
        if error != nil { error.memory = errorMsg("write(...) failed.") }
        return false
      }
      sent += s
    }
    return true
  }

  static func acceptSocket(socket: CInt, error:NSErrorPointer = nil) -> CInt? {
    var addr = sockaddr(sa_len: 0, sa_family: 0, sa_data: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)), len: socklen_t = 0
    let clientSocket = accept(socket, &addr, &len)
    if ( clientSocket != -1 ) {
      return clientSocket
    }
    if error != nil { error.memory = errorMsg("accept(...) failed.") }
    return nil
  }

  static func nextInt8(socket: CInt) -> Int {
    var buffer = [UInt8](count: 1, repeatedValue: 0);
    let next = recv(socket, &buffer, UInt(buffer.count), 0)
    if next <= 0 { return next }
    return Int(buffer[0])
  }

  static func read(socket: CInt, error:NSErrorPointer) -> String? {
    var chars: String = ""
    var n = 0
    do {
      n = nextInt8(socket)
      if ( n > 13 ) {
        chars.append(Character(UnicodeScalar(n)))
      }
    } while ( n > 0 && n != 10)

    if ( n == -1 && chars.isEmpty ) {
      if error != nil { error.memory = errorMsg("recv(...) failed.") }
      return nil
    }
    return chars
  }

  static func port_htons(port: in_port_t) -> in_port_t {
    return (Int(OSHostByteOrder()) == OSBigEndian ? port : _OSSwapInt16(port))
  }

  static func release(socket: CInt) {
    shutdown(socket, SHUT_RDWR)
    close(socket)
  }

}
