import Foundation

final class DictInstantiator: Instantiator {
  init() {}
  
  func createInstance(className: String) -> UnpicklerValue {
    return .object(([AnyHashable: Any](), Constants.typeName))
  }
  
  func initializeInstance(object: UnpicklerValue, arguments: Any) {
    
  }
  
  var unpickledTypeNames: [String] { [Constants.typeName] }
  
  var recognizedClassNames: [String] {
    Constants.classNames
  }
    
  struct Constants {
    static let typeName = "Dict"
    static let classNames = [
      "collections" + InstanceFactory.Constants.moduleDivider + "OrderedDict"
    ]
  }
}
