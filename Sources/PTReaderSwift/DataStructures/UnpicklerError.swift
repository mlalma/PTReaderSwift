import Foundation

/// Errors that can occur during unpickling operations.
public enum UnpicklerError: Error, Sendable {
    /// Frame data has been exhausted before completing the operation.
    case frameExhausted
    /// Frame is in an unexpected or invalid state.
    case unexpectedFrameState
    /// General error with a descriptive message.
    case error(String)
    /// Unexpected end of file encountered.
    case eof
    /// Pickle protocol version is not supported.
    case unsupportedProtocol(Int)
    /// Persistent ID operation is not supported.
    case unsupportedPersistentId
    /// Byte count value is negative.
    case negativeByteCount
    /// Data size exceeds maximum allowed size.
    case exceedsMaxSize
    /// Memo entry not found at the specified index.
    case memoNotFound(Int)
    /// Argument value is negative where positive expected.
    case negativeArgument
    /// Extension code is not registered.
    case unregisteredExtension(Int)
    /// Class could not be instantiated during unpickling.
    case classCouldNotBeInstantiated
}

