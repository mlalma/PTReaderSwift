import Foundation
import ZIPFoundation
import MLX
import MLXUtilsLibrary

@PTReaderActor
protocol TensorDataLoader {
  func load(dataType: String, key: String) throws -> (Data, String)
}

@PTReaderActor
final class PTFile {
  enum ParsingError : Error {
    case couldNotUnarchive
    case couldNotGetPTParams
    case couldNotLoadTensor
  }
  
  enum NumberFormat : String {
    case littleEndian = "little"
    case bigEndian = "big"
  }
  
  var archive: Archive!
  var version: Int?
  var storageAlignment: Int?
  var numberFormat: NumberFormat?
  var parsedData: UnpicklerValue?
  
  private func readString(entry: Entry) throws -> String? {
    var output: String?
    _ = try archive.extract(entry, consumer: { (data) in
      output = String(data: data, encoding: .utf8)
    })
    return output
  }
  
  private func readInt(entry: Entry) throws -> Int? {
    if let str = try readString(entry: entry) {
      return Int(str, radix: 10)
    }
    return nil
  }
  
  init(fileName: URL) throws {
    guard let archive = try? Archive(url: fileName, accessMode: .read, pathEncoding: nil) else {
      throw ParsingError.couldNotUnarchive
    }
    self.archive = archive
    
    if let versionEntry = archive["archive/.format_version"] {
      version = try readInt(entry: versionEntry)
    } else {
      version = nil
    }
    
    if let storageAlignmentEntry = archive["archive/.storage_alignment"] {
      storageAlignment = try readInt(entry: storageAlignmentEntry)
    } else {
      storageAlignment = nil
    }
    
    if let byteOrderEntry = archive["archive/byteorder"] {
      numberFormat = NumberFormat(rawValue: try readString(entry: byteOrderEntry) ?? "")
    } else {
      numberFormat = nil
    }
    
    if let dataEntry = archive["archive/data.pkl"] {
      var data: Data?
      _ = try archive.extract(dataEntry, bufferSize: Int(dataEntry.uncompressedSize), consumer: { (extractedData) in
        data = extractedData
      })
      
      if let data {
        parseData(data)
      }
    }
  }
  
  private func parseData(_ data: Data) {
    let unpickler = Unpickler(inputData: data, tensorLoader: self)
    if let object = try? unpickler.load() {
      parsedData = object
      logPrint("Unpickled this object \(String(describing: object))")
    } else {
      logPrint("Could not unpickle object out of the data")
    }
  }
}

extension PTFile: TensorDataLoader {
  func load(dataType: String, key: String) throws -> (Data, String) {
    if let tensorData = archive["archive/data/" + key] {
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
}
