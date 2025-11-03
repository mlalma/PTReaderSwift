import Foundation

final class InstanceFactory {
  var classNameInstantiators: [String: Instantiator] = [:]
  var unpickedNameInstantiators: [String: Instantiator] = [:]
  
  init() {
    addInstantiator(TensorInstantiator())
    addInstantiator(UntypedStorageInstantiator())
    addInstantiator(DictInstantiator())
  }
  
  private func addInstantiator(_ instantiator: Instantiator) {
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
  
  struct Constants {
    static let moduleDivider = "||"
  }
}
