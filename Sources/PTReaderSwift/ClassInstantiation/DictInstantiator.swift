import Foundation

final class DictInstantiator: Instantiator {
  init() {}
  
  func createInstance(className: String) -> UnpicklerValue {
    return .object(([AnyHashable: Any](), "Dict"))
  }
  
  func initializeInstance(object: UnpicklerValue, arguments: Any) {
  }
  
  var recognizedClassNames: [String] {
    Constants.classNames
  }
    
  struct Constants {
    static let classNames = [
      "collections" + InstanceFactory.Constants.moduleDivider + "OrderedDict"
    ]
  }
}
