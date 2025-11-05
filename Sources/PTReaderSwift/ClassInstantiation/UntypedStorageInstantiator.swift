import Foundation

final class UntypedStorageInstantiator: Instantiator {
  init() {}
  
  func createInstance(className: String) -> UnpicklerValue {
    return .object((Data(), className))
  }
  
  func initializeInstance(object: UnpicklerValue, arguments: UnpicklerValue)  -> UnpicklerValue {
    object
  }
  
  var unpickledTypeNames: [String] {
    ["DoubleStorage", "FloatStorage", "HalfStorage", "LongStorage",
     "IntStorage", "ShortStorage", "CharStorage", "ByteStorage",
     "BoolStorage", "BFloat16Storage", "CompleteFloatStorage"]
  }
  
  var recognizedClassNames: [String] {
    unpickledTypeNames.map { "torch" + InstanceFactory.Constants.moduleDivider + $0 }
  }
  
  struct Constants {
    /* static let classNames = [
      "torch" + InstanceFactory.Constants.moduleDivider + "IntStorage"
    ] */
  }
}

