import Foundation
import ZIPFoundation
import MLX

protocol TensorDataLoader {
  func load(dataType: String, key: String) throws -> (Data, String)
}

class PTFile {
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
  var version: Int!
  var storageAlignment: Int!
  var format: NumberFormat!
  
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
    var parsedVersion: Int?
    var parsedStorageAlignment: Int?
    var parsedByteOrder: String?
  
    guard let archive = try? Archive(url: fileName, accessMode: .read, pathEncoding: nil) else {
      throw ParsingError.couldNotUnarchive
    }
    self.archive = archive
    
    for entry in archive {
      print("ENTRY")
      print("  PATH: " + entry.path)
      print("  COMPRESSED SIZE: \(entry.compressedSize)")
      print("  UNCOMPRESSED SIZE: \(entry.uncompressedSize)")
      
      if entry.path == "archive/.format_version" {
        parsedVersion = try readInt(entry: entry)
      } else if entry.path == "archive/.storage_alignment" {
        parsedStorageAlignment = try readInt(entry: entry)
      } else if entry.path == "archive/byteorder" {
        parsedByteOrder = try readString(entry: entry)
      } else if entry.path == "archive/data.pkl" {
        var data: Data?
        _ = try archive.extract(entry, bufferSize: Int(entry.uncompressedSize), consumer: { (extractedData) in
          data = extractedData
        })
        
        if let data {
          parseData(data)
        }
      }
    }
    
    guard let parsedVersion, let parsedStorageAlignment, let parsedByteOrder, let parsedNumberFormat = NumberFormat(rawValue: parsedByteOrder) else {
      throw ParsingError.couldNotGetPTParams
    }
    
    self.version = parsedVersion
    self.storageAlignment = parsedStorageAlignment
    self.format = parsedNumberFormat
  }
  
  private func parseData(_ data: Data) {
    let unpickler = Unpickler(inputData: data, tensorLoader: self)
    let object = try? unpickler.load()
    debugPrint("Unpickled this object \(object ?? "NO OBJECT")")
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
