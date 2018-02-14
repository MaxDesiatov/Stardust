//
//  main.swift
//  Stardust
//
//  Created by Max Desiatov on 14/02/2018.
//  Copyright © 2018 Max Desiatov. All rights reserved.
//

import Foundation
import Dispatch

let ch = Channel<Int>(label: "int")
let bch = Channel<BInt>(label: "big")

DispatchQueue.global().async {
  let v = ch.receive()
  bch.send(factorial(v))
}

for i in 1..<100 {
  ch.send(i)
}
