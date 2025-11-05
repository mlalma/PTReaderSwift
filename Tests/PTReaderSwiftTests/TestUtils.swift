import Foundation
import ZIPFoundation
import MLXUtilsLibrary
@testable import PTReaderSwift

func debugArchive(url: URL) {
  guard let archive = try? Archive(url: url, accessMode: .read, pathEncoding: nil) else {
    return
  }
  
  for entry: Entry in archive {
    logPrint("Entry")
    logPrint("  Path: \(entry.path)")
    logPrint("  Type: \(entry.type)")
    logPrint("  Is compressed: \(entry.isCompressed)")
    logPrint("  Compressed size: \(entry.compressedSize)")
    logPrint("  Uncompressed size: \(entry.uncompressedSize)")
    logPrint("  Checksum: \(entry.checksum)")
    logPrint("=================================")
  }
}

func findFile(_ fileName: String, _ fileExtension: String) -> URL? {
  Bundle.module.url(forResource: fileName, withExtension: fileExtension,  subdirectory: "Resources")
}
