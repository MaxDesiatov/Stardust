//
//  main.swift
//  Stardust
//
//  Created by Max Desiatov on 14/02/2018.
//  Copyright © 2018 Max Desiatov. All rights reserved.
//

import Foundation
import Dispatch

let inp = Chan<Int>()

func worker(_ input: RChan<Int>) -> RChan<(Int, BInt)> {
  let out = Chan<(Int, BInt)>()
  DispatchQueue.global().async {
    while let v = input.read() {
      out.write((v, factorial(v)))
    }
  }
  return out.reader
}

let workers = (0..<4).map { _ in worker(inp.reader) }

DispatchQueue.global().async {
  select(workers) { i, f in
    print("factorial(\(i)) is \(f)")
  }
}

for i in 1..<100 {
  inp.write(i)
}

