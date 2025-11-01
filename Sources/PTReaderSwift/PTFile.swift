import Foundation
import ZIPFoundation
import MLX

class PTFile {
  enum parsingError : Error {
    case couldNotUnarchive
    case couldNotGetPTParams
  }
  
  enum numberFormat : String {
    case littleEndian = "little"
    case bigEndian = "big"
  }
  
  var archive: Archive!
  var version: Int!
  var storageAlignment: Int!
  var format: numberFormat!
  
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
      throw parsingError.couldNotUnarchive
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
        var data = Data()
        _ = try archive.extract(entry, bufferSize: Int(entry.uncompressedSize), consumer: { (extractedData) in
          data = extractedData
        })
        parseData(data)
      }
    }
    
    guard let parsedVersion, let parsedStorageAlignment, let parsedByteOrder, let parsedNumberFormat = numberFormat(rawValue: parsedByteOrder) else {
      throw parsingError.couldNotGetPTParams
    }
    
    self.version = parsedVersion
    self.storageAlignment = parsedStorageAlignment
    self.format = parsedNumberFormat
  }
  
  private func loadTensor(dType: DType, numberOfElements: Int64, key: String, location: String) {
    // TO_DO: Code this
  }
  
  private func parseData(_ data: Data) {
    let unpickler = Unpickler(inputData: data)
    let object = try? unpickler.load()
    debugPrint("Unpickled this object \(object ?? "NO OBJECT")")
  }
}
