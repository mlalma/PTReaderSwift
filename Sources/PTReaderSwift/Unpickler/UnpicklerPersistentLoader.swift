import Foundation

/// Called when persistent ID loading is requested
@PTReaderActor
protocol UnpicklerPersistentLoader: AnyObject {
  /// Handle persistent load, which reads the data e.g. for tensor objects on .pt files.
  /// - Parameter pid: Array of parameters that need to be unpacked.
  /// - Returns: Generated object.
  func load(_ savedId: [UnpicklerValue]) throws -> UnpicklerValue
}
