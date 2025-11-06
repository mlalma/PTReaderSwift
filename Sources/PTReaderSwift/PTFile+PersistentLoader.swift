import Foundation
import MLX
internal import MLXUtilsLibrary

@PTReaderActor
extension PTFile : UnpicklerPersistentLoader {
  /// Handle persistent load, which reads the data for tensor objects.
  /// - Parameter pid: Array of parameters that need to be unpacked.
  /// - Returns: Generated tensor object (MLXArray).
  func load(_ savedId: [UnpicklerValue]) throws -> UnpicklerValue {
    guard let firstVal = savedId.first,
          savedId.count >= 5  else {
      throw UnpicklerError.unsupportedPersistentId
    }
          
    guard let typeName = maybeDecodeAscii(from: firstVal),
          typeName == Constants.storageTypeNameForLoadingTensor else {
      throw UnpicklerError.unsupportedPersistentId
    }
    
    // We are doing these checks to verify that input data is valid and that Unpickler can parse it
    guard let _ = savedId[1].objectType(Data.self),
      let storageObjectTypeName = savedId[1].objectName,
      let _ = savedId[1].dtype,
      let key = savedId[2].string,
      let _ = maybeDecodeAscii(from: savedId[3]),
      let _ = savedId[4].int else {
      throw UnpicklerError.unsupportedPersistentId
    }
            
    if let cachedStorage = storageCache[key] {
      return .object(cachedStorage)
    } else {
      guard let newStorage = try? loadTensor(dataType: storageObjectTypeName, key: key) else {
        throw UnpicklerError.unsupportedPersistentId
      }
      
      // TODO: Perform byteswapping here if needed based on byteorderdata parsed in PTFile
      
      storageCache[key] = newStorage
      return .object(newStorage)
    }
  }
  
  /// Loads tensor data.
  /// - Parameters:
  ///   - dataType: Data type to load
  ///   - key: Key to use to identify the datafile inside .pt file
  /// - Returns: Parsed tensor data.
  private func loadTensor(dataType: String, key: String) throws -> (Data, String) {
    if let tensorData = findArchiveEntry(ending: "/data/" + key) {
      var data: Data?
      _ = try archive.extract(tensorData, bufferSize: Int(tensorData.uncompressedSize), consumer: { (extractedData) in
        data = extractedData
      })
      
      if let data {
        return (data, dataType)
      }
    }
    
    throw ParsingError.couldNotLoadTensor
  }
  
  /// Decodes ascii string from bytestring if it is defined, otherwise returns string.
  /// - Parameter value: Value to check
  /// - Returns: String or nil if the value is not a string.
  private func maybeDecodeAscii(from value: UnpicklerValue) -> String? {
    if case .string(let str) = value {
      return str
    } else if case .bytes(let byteStr) = value {
      return String(bytes: byteStr, encoding: .ascii)
    }
    return nil
  }
}
