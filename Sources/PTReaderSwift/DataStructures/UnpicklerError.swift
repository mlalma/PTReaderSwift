import Foundation

// Error type for unpickling errors.
enum UnpicklerError: Error, Sendable {
  case frameExhausted
  case unexpectedFrameState
  case error(String)
  case eof
  case unsupportedProtocol(Int)
  case unsupportedPersistentId
  case negativeByteCount
  case exceedsMaxSize
  case memoNotFound(Int)
  case negativeArgument
  case unregisteredExtension(Int)
  case classCouldNotBeInstantiated
}

