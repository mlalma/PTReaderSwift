import Foundation
import Dispatch

/// Global actor for coordinating .pt file reading operations.
/// Uses a custom serial dispatch queue with user-initiated QoS.
@globalActor
public final actor PTReaderActor {
    public static let shared = PTReaderActor()
    
    private let queue = DispatchSerialQueue(
        label: "ptreader.actor.queue",
        qos: .userInitiated
    )
    
    public nonisolated var unownedExecutor: UnownedSerialExecutor {
        queue.asUnownedSerialExecutor()
    }
}
