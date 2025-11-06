import Foundation
internal import ZIPFoundation
import MLX
internal import MLXUtilsLibrary

/// Reader for PyTorch .pt files, handling ZIP archive extraction and unpickling.
@PTReaderActor
public final class PTFile {
    /// Errors that can occur during .pt file parsing.
    enum ParsingError: Error {
        case couldNotUnarchive
        case couldNotGetPTParams
        case couldNotLoadTensor
    }
    
    /// Binary number format for tensor data.
    enum NumberFormat: String {
        case littleEndian = "little"
        case bigEndian = "big"
    }
    
    internal var archive: Archive!
    var version: Int?
    var storageAlignment: Int?
    var numberFormat: NumberFormat?
    var parsedData: UnpicklerValue?
    internal var parsedArchiveEntries: [(path: String, entry: Entry)] = []
    internal var storageCache: [String: (Data, String)] = [:]
    
    /// Extracts and decodes a string from an archive entry.
    private func readString(entry: Entry) throws -> String? {
        var output: String?
        _ = try archive.extract(entry, consumer: { data in
            output = String(data: data, encoding: .utf8)
        })
        return output
    }
    
    /// Extracts and parses an integer from an archive entry.
    private func readInt(entry: Entry) throws -> Int? {
        if let str = try readString(entry: entry) {
            return Int(str, radix: 10)
        }
        return nil
    }
    
    /// Reads and caches all archive entries for quick lookup.
    private func readArchiveEntries() {
        for entry in archive {
            parsedArchiveEntries.append((path: entry.path, entry: entry))
        }
    }
    
    /// Finds an archive entry by path suffix.
    internal func findArchiveEntry(ending: String) -> Entry? {
        parsedArchiveEntries.first { $0.path.hasSuffix(ending) }?.entry
    }
    
    /// Initializes a PTFile from a .pt file URL.
    public init(fileName: URL) throws {
        guard let archive = try? Archive(url: fileName, accessMode: .read, pathEncoding: nil) else {
            throw ParsingError.couldNotUnarchive
        }
        self.archive = archive
        readArchiveEntries()
        
        if let versionEntry = findArchiveEntry(ending: "/.format_version") {
            version = try readInt(entry: versionEntry)
        } else {
            version = nil
        }
        
        if let storageAlignmentEntry = findArchiveEntry(ending: "/.storage_alignment") {
            storageAlignment = try readInt(entry: storageAlignmentEntry)
        } else {
            storageAlignment = nil
        }
        
        if let byteOrderEntry = findArchiveEntry(ending: "/byteorder") {
            numberFormat = NumberFormat(rawValue: try readString(entry: byteOrderEntry) ?? "")
        } else {
            numberFormat = nil
        }
    }
    
    /// Parses and unpickles the main data from the .pt file.
    public func parseData() -> UnpicklerValue? {
        guard parsedData == nil else { return parsedData }
        
        do {
            if let dataEntry = findArchiveEntry(ending: "/data.pkl") {
                var data: Data?
                _ = try archive.extract(
                    dataEntry,
                    bufferSize: Int(dataEntry.uncompressedSize),
                    consumer: { extractedData in
                        data = extractedData
                    }
                )
                
                if let data {
                    let unpickler = Unpickler(inputData: data, persistentLoader: self)
                    if let object = try unpickler.load() {
                        parsedData = object
                        logPrint("Unpickled this object \(String(describing: object))")
                        return parsedData
                    } else {
                        logPrint("Could not unpickle object out of the data")
                    }
                }
            }
        } catch let ex {
            logPrint("Unpickling failed with error: \(ex)")
        }
        
        return nil
    }
    
    struct Constants {
        /// Persistent loader type for tensor storage.
        static let storageTypeNameForLoadingTensor = "storage"
    }
}
