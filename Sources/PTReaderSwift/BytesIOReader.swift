import Foundation

/// Provides sequential read operations on a Data buffer.
final class BytesIOReader {
  private var data: Data
  private var position: Int
  
  /// Flag indicating if we are in the end of the stream.
  var endOfData: Bool {
    return position >= data.count
  }

  /// Constructor.
  /// - Parameter data: Data block to read from.
  init(data: Data) {
    self.data = data
    self.position = 0
  }
    
  /// Reads data into a buffer.
  /// - Parameter buffer: Buffer to read data into (modified in place).
  /// - Returns: Number of bytes actually read.
  func readinto(_ buffer: inout Data) -> Int {
    let bytesToRead = min(buffer.count, data.count - position)
    if bytesToRead <= 0 {
        return 0
    }
    
    let range = position..<(position + bytesToRead)
  
    buffer.replaceSubrange(0..<bytesToRead, with: data[range])
    position += bytesToRead
    return bytesToRead
  }
    
  /// Reads n bytes from the current position
  /// - Parameter n: Number of bytes to read
  /// - Returns: Data containing the bytes read (may be less than n if end of data is reached)
  func read(_ n: Int) -> Data {
    let bytesToRead = min(n, data.count - position)
    if bytesToRead <= 0 {
        return Data()
    }
    
    let range = position..<(position + bytesToRead)
    let result = data[range]
    position += bytesToRead
    return result
  }
    
  /// Read a line (up to and including newline character)
  /// - Returns: Data containing the line read
  func readline() -> Data {
    if position >= data.count {
      return Data()
    }
    
    var result = Data()
    while position < data.count {
      let byte = data[position]
      position += 1
      result.append(byte)
      if byte == UInt8(ascii: "\n") {
        break
      }
    }
    return result
  }
}
