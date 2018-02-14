//
//  Channel.swift
//  Stardust
//
//  Created by Max Desiatov on 14/02/2018.
//  Copyright © 2018 Max Desiatov. All rights reserved.
//

import Foundation
import Dispatch

class Channel<T> {
  private let q: DispatchQueue
  private let writeSemaphore = DispatchSemaphore(value: 0)
  private let readSemaphore = DispatchSemaphore(value: 0)
  private var value: T?

  init(label: String) {
    q = DispatchQueue(label: label)
  }

  // block until value becomes nil, set the prop to new value and return
  func send(_ value: T) -> () {
    if self.value != nil {
      writeSemaphore.wait()
    }
    q.sync {
      self.value = value
    }
    readSemaphore.signal()
  }

  // block until value becomes not nil, get the value, set prop back to nil
  // and return it
  func receive() -> T {
    readSemaphore.wait()
    var v: T!
    q.sync {
      v = value
      value = nil
    }
    writeSemaphore.signal()
    return v
  }
}

