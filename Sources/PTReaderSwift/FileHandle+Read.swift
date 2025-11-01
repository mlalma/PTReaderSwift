import Foundation

/// Extension to provide reading methods for FileHandle.
extension FileHandle {
  /// Reads exactly n bytes from the file.
  /// - Parameter count: Number of bytes to read.
  /// - Returns: Data containing exactly n bytes.
  /// - Throws: Error if unable to read the requested number of bytes (EOF).
  func readExactly(_ count: Int) throws -> Data {
    guard let data = try self.read(upToCount: count), data.count == count else {
      throw POSIXError(.EIO, userInfo: [NSLocalizedDescriptionKey: "Unexpected end of file"])
    }
    return data
  }
  
  /// Reads a line from the file (up to and including newline).
  /// - Returns: Data containing the line, including the newline character if present.
  func readLine() -> Data {
    var result = Data()
    
    while let byte = try? self.read(upToCount: 1), !byte.isEmpty {
      result.append(byte)
      if byte[0] == UInt8(ascii: "\n") {
        break
      }
    }
    return result
  }
}
