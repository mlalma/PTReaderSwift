import Foundation
import Dispatch

@globalActor
actor PTReaderActor {
  static let shared = PTReaderActor()
  
  private let queue = DispatchSerialQueue(label: "ptreader.actor.queue", qos: .userInitiated)

  nonisolated var unownedExecutor: UnownedSerialExecutor {
    queue.asUnownedSerialExecutor()
  }
}
