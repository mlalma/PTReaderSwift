import Foundation
import MLXUtilsLibrary

final class DictInstantiator: Instantiator {
  init() {}
  
  func createInstance(className: String) -> UnpicklerValue {
    return .object(([AnyHashable: Any](), Constants.typeName))
  }
  
  func initializeInstance(object: UnpicklerValue, arguments: UnpicklerValue) {
    guard let arglist = arguments.toAny() as? [Any],
          var objectInstance = (object.toAny() as? ([AnyHashable: Any], String))?.0 else {
      logPrint("Could not parse argument list \(arguments) for object \(object)")
      return
    }

    for arg in arglist {
      guard let keyValuePair = arg as? [Any], keyValuePair.count == 2, let key = keyValuePair[0] as? AnyHashable else {
        continue
      }
      objectInstance[key] = keyValuePair[1]
    }
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
