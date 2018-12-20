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
private let counterSemaphore = DispatchSemaphore(value: 1)

//func select<T>(_ chans: [Chan<T>: (T) -> ()], def: (() -> ())? = nil) {
//  fatalError("not implemented")
//}

func select<T>(_ chans: [RChan<T>], any: (T) -> ()) {
  let s = DispatchSemaphore(value: 0)

  // FIXME: use something thread-safe instead of an array, OR dispatch source?
  // OR dispatch source will probably only support up to 64 channels (64-bits
  // of the dispatch source int with a bit for each channel)
  var ready = [RChan<T>]()

  defer {
    for c in chans {
      c.ch.clearUpdated()
    }
  }

  for c in chans {
    c.ch.updated {
      if !$0 {
        ready.append(c)
        s.signal()
      }
    }
  }

  s.wait()

  guard ready.count > 0 else {
    return
  }

  // FIXME: reading from `ready` is unsafe here, other `updated` closures
  // might still be writing to it concurrently
  if ready.count == 1, let c = ready.first, let v = c.read() {
    any(v)
    return
  }

  // pick ready channel randomly to prevent too fast channels always winning
  let random = Int(arc4random_uniform(UInt32(ready.count)))

  if let v = chans[random].read() {
    any(v)
  }
}

func select<T>(_ chans: [RChan<T>], any: (T) -> (), def: (() -> ())? = nil) {
  fatalError("not implemented")
}

func dispatch(qos: DispatchQoS.QoSClass = .default, closure: @escaping () -> ()) {
  DispatchQueue.global(qos: qos).async(execute: closure)
}

final class Chan<T>: Hashable, Equatable {
  static func ==(lhs: Chan<T>, rhs: Chan<T>) -> Bool {
    return lhs.tag == rhs.tag
  }

  private let tag: Int
  private let q: DispatchQueue
  private let writeSemaphore = DispatchSemaphore(value: 0)
  private let readSemaphore = DispatchSemaphore(value: 0)
  private var value: T?
  private var isClosed = false
  private var onUpdate: ((Bool) -> ())?

  var hashValue: Int {
    return tag
  }

  init() {
    counterSemaphore.wait()

    tag = counter
    q = DispatchQueue(label: "com.chan.\(counter)")
    counter += 1
    if counter == Int.max {
      fatalError("channel tag counter exhausted with \(counter) channels")
    }
    counterSemaphore.signal()
  }

  fileprivate func clearUpdated() {
    q.sync {
      onUpdate = nil
    }
  }

  fileprivate func updated(_ handler: @escaping (Bool) -> ()) -> Bool {
    var isClosed: Bool!
    q.sync {
      isClosed = self.isClosed

      if value != nil {
        handler(true)
      } else if !isClosed {
        onUpdate = handler
      }
    }

    return isClosed
  }

  func close() {
    q.sync {
      isClosed = true
      onUpdate?(true)
    }
  }

  // block until value becomes nil, set the prop to new value and return
  // FIXME: do nothing or throw if closed? deadlines?
  func write(_ v: T) -> () {
    q.sync {
      if isClosed {
        return
      }
      if value != nil {
        writeSemaphore.wait()
      }
        
      value = v
      readSemaphore.signal()
    }
  }

  // Return the value if not nil, set `value` prop to nil.
  // Otherwise block until value becomes not nil,
  // get the value, set `value` prop back to nil and return it
  // FIXME: return nil or throw if closed? deadlines?
  func read() -> T? {
    var v: T? = nil
    q.sync {
      guard value == nil else {
        v = value
        value = nil
        return
      }

      guard !isClosed else {
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
  fileprivate let ch: Chan<T>

  init(_ ch: Chan<T>) {
    self.ch = ch
  }

  func read() -> T? {
    return ch.read()
  }
}

struct WChan<T> {
  fileprivate let ch: Chan<T>

  init(_ ch: Chan<T>) {
    self.ch = ch
  }

  func write(_ value: T) -> () {
    ch.write(value)
  }
}
