import Foundation
internal import MLXUtilsLibrary

/// Instantiator for dictionary objects, including Python's `OrderedDict`.
final class DictInstantiator: Instantiator {
    /// Constructor.
    init() {}
    
    /// Creates an empty dictionary instance.
    func createInstance(className: String) -> UnpicklerValue {
        return .object(([AnyHashable: Any](), Constants.typeName))
    }
    
    /// Initializes the dictionary with key-value pairs from the arguments list.
    func initializeInstance(object: UnpicklerValue, arguments: UnpicklerValue) -> UnpicklerValue {
        guard let arglist = arguments.list,
              var objectInstance = object.objectType([AnyHashable: Any].self) else {
            logPrint("Could not parse argument list \(arguments) for object \(object)")
            return object
        }
        
        for arg in arglist {
            guard let keyValuePair = arg.list,
                  keyValuePair.count == 2,
                  let key = keyValuePair[0].toAny() as? AnyHashable else {
                continue
            }
            objectInstance[key] = keyValuePair[1].toAny()
        }
        
        return object
    }
    
    var unpickledTypeNames: [String] {
        [Constants.typeName]
    }
    
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
