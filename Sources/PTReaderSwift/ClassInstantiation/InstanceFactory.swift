import Foundation

@PTReaderActor
final class InstanceFactory {
  var classNameInstantiators: [String: Instantiator] = [:]
  var unpickedNameInstantiators: [String: Instantiator] = [:]
  
  static let shared = InstanceFactory()
  
  private init() {
    addInstantiator(TensorInstantiator())
    addInstantiator(UntypedStorageInstantiator())
    addInstantiator(DictInstantiator())
  }
  
  func addInstantiator(_ instantiator: Instantiator) {
    for className in instantiator.recognizedClassNames {
      classNameInstantiators[className] = instantiator
    }
    
    for unpickledTypeName in instantiator.unpickledTypeNames {
      unpickedNameInstantiators[unpickledTypeName] = instantiator
    }
  }
  
  func createInstance(module: String? = nil, className: String) -> UnpicklerValue? {
    let fullClassName = module != nil ? "\(module!)\(Constants.moduleDivider)\(className)" : className
    
    if let instantiator = classNameInstantiators[fullClassName] {
      return instantiator.createInstance(className: className)
    }
   
    return nil
  }
  
  func initializeInstance(object: UnpicklerValue, arguments: UnpicklerValue) -> UnpicklerValue {
    if let objectName = object.objectName {
      if let instantiator = unpickedNameInstantiators[objectName] {
        return instantiator.initializeInstance(object: object, arguments: arguments)
      }
    } else if var dict = object.dict, let argDict = arguments.dict {
      for (key, value) in argDict {
        dict[key] = value
        print("AAAAAAA KEY \(key)")
      }
      return .dict(dict)
    }
    return object
  }
  
  struct Constants {
    static let moduleDivider = "||"
  }
}
