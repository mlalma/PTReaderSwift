import Foundation

final class UntypedStorageInstantiator: Instantiator {
  init() {}
  
  func createInstance(className: String) -> UnpicklerValue {
    return .object((Data(), className))
  }
  
  func initializeInstance(object: UnpicklerValue, arguments: Any) {
  }
    
  var recognizedClassNames: [String] {
    Constants.classNames
  }
  
  struct Constants {
    static let classNames = [
      "torch" + InstanceFactory.Constants.moduleDivider + "IntStorage"
    ]
  }
}

