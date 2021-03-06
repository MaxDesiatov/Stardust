import Dispatch

//protocol AnyActor {
//
//}
//
//class Actor<T>: AnyActor {
//  private let q: DispatchQueue
//
//  init(name: String, q: DispatchQueue? = nil) {
//    guard let q = q else {
//      self.q = DispatchQueue(label: name)
//      return
//    }
//
//    self.q = q
//
//    start()
//  }
//
//  func start() {
//  }
//
//  func receive(_ msg: T, sender: AnyActor?) {
//    fatalError("implement receive in a subclass")
//  }
//
//  // FIXME: try appending to a mailbox instead of queuing closures, also benchmark
//  final func send<M>(_ msg: M, to receiver: Actor<M>) {
//    receiver.q.async { [weak self] in
//      receiver.receive(msg, sender: self)
//    }
//  }
//}

protocol Actor {
    associatedtype Message
    associatedtype Props
    
    init(_: Props)
    
    func receive(message: Message)
}

protocol AnyRemoteActor {}

protocol RemoteActor: Actor, AnyRemoteActor where Message: Codable, Props: Codable {
}

extension Actor {
    func spawn<T: Actor>(_: T.Type, _: T.Props) {
    }
}

struct ActorID<T: Actor> {
    let value: String
    
    func send(_ message: T.Message) {
    }
}

protocol MapperResponse {
    associatedtype Value
    static func response(_: Value) -> Self
}

struct Mapper<T, U>: Actor where U: Actor, U.Message: MapperResponse {
    struct Request {
        let value: T
        let callback: ActorID<U>
    }
    
    private let map: (T) -> U.Message.Value
    
    init(_ map: @escaping (T) -> U.Message.Value) {
        self.map = map
    }
    
    func receive(message: Request) {
        let result = U.Message.response(map(message.value))
        message.callback.send(result)
    }
}

struct A: RemoteActor {
    let i: Int
    init(_ i: Int) {
        self.i = i
    }
    
    func receive(message: Int) {
        
    }
}

let t = A.self
let y: Any = A(5)

func cast<T>(value: Any, to type: T.Type) -> T? {
    return value as? T
}

let z = cast(value: y, to: t)

var registered = [Any.Type]()

func register<T: RemoteActor>(remoteActor: T.Type) {
    registered.append(remoteActor)
    registered.append(T.Props.self)
}

register(remoteActor: A.self)

enum Request {
  case request(Int)
}

enum Response {
  case response(Int, BInt)
}

func factorial(_ i: Int) -> BInt {
  return i > 0 ? (1..<i).reduce(1) { return $0 * $1 } : 1

}

struct Factorial: Actor {
  func receive(_ message: Request) {

  }
}

//final class Factorial: Actor<Request> {
//  override func receive(_ msg: Request, sender: AnyActor?) {
//    guard let sender = sender as? Actor<Response>,
//      case let .request(i) = msg else { return }
//
//    let result = factorial(i)
//    send(.response(i, result), to: sender)
//  }
//}
//
//final class Main: Actor<Response> {
//  override func start() {
//    var children = [Factorial]()
//    for i in 0..<4000 {
//      children.append(Factorial(name: "\(i)"))
//    }
//
//    for i in 1000..<5000 {
//      send(.request(i), to: children[i - 1000])
//    }
//  }
//
//  override func receive(_ msg: Response, sender: AnyActor?) {
//    guard case let .response(request, response) = msg else { return }
//
//    print("received result")
//  }
//}
