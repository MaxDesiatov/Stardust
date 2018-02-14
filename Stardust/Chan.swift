//
//  Channel.swift
//  Stardust
//
//  Created by Max Desiatov on 14/02/2018.
//  Copyright © 2018 Max Desiatov. All rights reserved.
//

import Foundation
import Dispatch

private var counter = Int.min
private let counterS = DispatchSemaphore(value: 1)

//func select<T>(_ chans: [Chan<T>: (T) -> ()], def: (() -> ())? = nil) {
//  fatalError("not implemented")
//}

func select<T>(_ chans: [RChan<T>], any: (T) -> ()) {
  fatalError("not implemented")
}

func select<T>(_ chans: [RChan<T>], any: (T) -> (), def: (() -> ())? = nil) {
  fatalError("not implemented")
}

class Chan<T>: Hashable, Equatable {
  static func ==(lhs: Chan<T>, rhs: Chan<T>) -> Bool {
    return lhs.tag == rhs.tag
  }

  private let tag: Int
  private let q: DispatchQueue
  private let writeSemaphore = DispatchSemaphore(value: 0)
  private let readSemaphore = DispatchSemaphore(value: 0)
  private var value: T?
  private var isClosed = false

  var hashValue: Int {
    return tag
  }

  init() {
    counterS.wait()

    tag = counter
    q = DispatchQueue(label: "com.chan.\(counter)")
    counter += 1
    counterS.signal()
  }

  // block until value becomes nil, set the prop to new value and return
  // FIXME: do nothing or throw if closed? deadlines?
  func write(_ value: T) -> () {
    q.sync {
      if isClosed {
        return
      }
      if self.value != nil {
        writeSemaphore.wait()
      }
        
      self.value = value
      readSemaphore.signal()
    }
  }

  // block until value becomes not nil, get the value, set prop back to nil
  // and return it
  // FIXME: return nil or throw if closed? deadlines?
  func read() -> T? {
    var v: T? = nil
    q.sync {
      if isClosed {
        return
      }
      readSemaphore.wait()
      v = value
      value = nil
      writeSemaphore.signal()
    }
    return v
  }

  var reader: RChan<T> {
    return RChan(self)
  }

  var writer: WChan<T> {
    return WChan(self)
  }
}

struct RChan<T> {
  private let ch: Chan<T>

  init(_ ch: Chan<T>) {
    self.ch = ch
  }

  func read() -> T? {
    return ch.read()
  }
}

struct WChan<T> {
  private let ch: Chan<T>

  init(_ ch: Chan<T>) {
    self.ch = ch
  }

  func write(_ value: T) -> () {
    ch.write(value)
  }
}
