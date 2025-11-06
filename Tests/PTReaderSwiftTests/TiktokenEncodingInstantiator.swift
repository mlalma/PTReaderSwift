import Foundation
import MLX
import MLXUtilsLibrary
@testable import PTReaderSwift

/// Instantiator for unpickling Tiktoken encoding objects from PyTorch files.
/// Handles deserialization of `tiktoken.core.Encoding` instances.
final class TiktokenEncodingInstantiator: Instantiator {
    
    init() {}
    
    /// Creates a new TiktokenEncoding instance.
    func createInstance(className: String) -> UnpicklerValue {
        return .object((TiktokenEncoding(), Constants.typeName))
    }
    
    /// Initializes the TiktokenEncoding instance with deserialized state.
    func initializeInstance(object: UnpicklerValue, arguments: UnpicklerValue) -> UnpicklerValue {
        if let argumentDict = arguments.dict,
           let encoder = object.objectType(TiktokenEncoding.self) {
            for (key, values) in argumentDict {
                if let keyString = key as? String {
                    switch keyString {
                    case "pat_str":
                        encoder.patStr = values as? String
                    case "name":
                        encoder.name = values as? String
                    case "special_tokens":
                        encoder.specialTokens = values as? [String: Int]
                    case "mergeable_ranks":
                        encoder.mergeableRanks = values as? [Data: Int]
                    default:
                        logPrint("Unknown state key when initializing TiktokenEncoding: \(keyString)")
                    }
                }
            }
        }
        return object
    }
    
    var recognizedClassNames: [String] {
        Constants.classNames
    }
    
    var unpickledTypeNames: [String] {
        [Constants.typeName]
    }
    
    struct Constants {
        static let typeName = "TiktokenEncoding"
        static let classNames = [
            "tiktoken.core" + InstanceFactory.Constants.moduleDivider + "Encoding"
        ]
    }
}
