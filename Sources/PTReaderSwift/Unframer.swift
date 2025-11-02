import Foundation

/// Handles frame-based reading from pickle files.
final class Unframer {
  private let readFromResource: (Int) -> Data
  private let readLineFromResource: () -> Data
  private var currentFrame: BytesIOReader?
  
  /// Consructor.
  /// - Parameters:
  ///   - fileRead: Closure that reads n bytes and returns Data
  ///   - fileReadline: Closure that reads a line and returns Data
  init(readFromResource: @escaping (Int) -> Data, readLineFromResource: @escaping () -> Data) {
    self.readFromResource = readFromResource
    self.readLineFromResource = readLineFromResource
    self.currentFrame = nil
  }
  
  /// Convenience initializer that creates an Unframer from a FileHandle.
  /// - Parameter fileHandle: The FileHandle to read from (should be opened for reading).
  convenience init(fileHandle: FileHandle) {
    self.init(
      readFromResource: { count in
        (try? fileHandle.readExactly(count)) ?? Data()
      },
      readLineFromResource: {
        fileHandle.readLine()
      }
    )
  }
    
  /// Reads data into a buffer.
  /// - Parameter buffer: Buffer to read data into (modified in place).
  /// - Returns: Number of bytes read.
  /// - Throws: UnpicklingError if pickle is exhausted before end of frame
  func readInto(_ buffer: inout Data) throws -> Int {
    if let frame = currentFrame {
      let n = frame.readinto(&buffer)
      if n == 0 && buffer.count != 0 {
        currentFrame = nil
        let size = buffer.count
        buffer = readFromResource(size)
        return size
      }
      
      if n < buffer.count {
        throw UnpicklerError.frameExhausted
      }
      return n
    } else {
      let size = buffer.count
      buffer = readFromResource(size)
      return size
    }
  }
    
  /// Read n bytes of data.
  /// - Parameter n: Number of bytes to read.
  /// - Returns: Data containing the bytes read.
  /// - Throws: UnpicklingError if pickle is exhausted before end of frame.
  func read(_ n: Int) throws -> Data {
    if let frame = currentFrame {
      let data = frame.read(n)
      if data.isEmpty && n != 0 {
        currentFrame = nil
        return readFromResource(n)
      }

      if data.count < n {
        throw UnpicklerError.frameExhausted
      }
      return data
    } else {
      return readFromResource(n)
    }
  }
    
  /// Read a line of data (up to and including newline).
  /// - Returns: Data containing the line read.
  /// - Throws: UnpicklingError if pickle is exhausted before end of frame.
  func readline() throws -> Data {
    if let frame = currentFrame {
      let data = frame.readline()
      if data.isEmpty {
        currentFrame = nil
        return readLineFromResource()
      }

      if data.last != UInt8(ascii: "\n") {
        throw UnpicklerError.frameExhausted
      }
      return data
    } else {
      return readLineFromResource()
    }
  }
    
  /// Load a new frame of the specified size.
  /// - Parameter frameSize: Size of the frame to load.
  /// - Throws: UnpicklingError if a new frame is started before current frame ends.
  func loadFrame(frameSize: Int) throws {
    if let frame = currentFrame {
      if !frame.endOfData {
          throw UnpicklerError.unexpectedFrameState
      }
    }
    let frameData = readFromResource(frameSize)
    currentFrame = BytesIOReader(data: frameData)
  }
}

