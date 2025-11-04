import Foundation
import MLX
import MLXUtilsLibrary
@testable import PTReaderSwift

final class TiktokenEncodingInstantiator: Instantiator {
  init() {}
  
  func createInstance(className: String) -> UnpicklerValue {
    return .object((NSObject(), Constants.typeName))
  }
  
  func initializeInstance(object: UnpicklerValue, arguments: UnpicklerValue) -> UnpicklerValue {
    // TODO: Let's see
    object
  }
  
  var recognizedClassNames: [String] {
    Constants.classNames
  }
  
  var unpickledTypeNames: [String] { [Constants.typeName] }
    
  struct Constants {
    static let typeName = "TiktokenEncoding"
    static let classNames = [
      "tiktoken.core" + InstanceFactory.Constants.moduleDivider + "Encoding"
    ]
  }
}
