import Foundation

/// Factory for managing instantiators that create and initialize custom objects during unpickling.
@PTReaderActor
public final class InstanceFactory {
    var classNameInstantiators: [String: Instantiator] = [:]
    var unpickedNameInstantiators: [String: Instantiator] = [:]
    
    public static let shared = InstanceFactory()
    
    private init() {
        addInstantiator(TensorInstantiator())
        addInstantiator(UntypedStorageInstantiator())
        addInstantiator(DictInstantiator())
    }
    
    /// Registers an instantiator for its recognized class names and unpickled type names.
    public func addInstantiator(_ instantiator: Instantiator) {
        for className in instantiator.recognizedClassNames {
            classNameInstantiators[className] = instantiator
        }
        
        for unpickledTypeName in instantiator.unpickledTypeNames {
            unpickedNameInstantiators[unpickledTypeName] = instantiator
        }
    }
    
    /// Creates an instance for the specified module and class name.
    func createInstance(module: String? = nil, className: String) -> UnpicklerValue? {
        let fullClassName = if let module {
            "\(module)\(Constants.moduleDivider)\(className)"
        } else {
            className
        }
        
        if let instantiator = classNameInstantiators[fullClassName] {
            return instantiator.createInstance(className: className)
        }
        
        return nil
    }
    
    /// Initializes an object with the provided arguments.
    func initializeInstance(object: UnpicklerValue, arguments: UnpicklerValue) -> UnpicklerValue {
        if let objectName = object.objectName,
           let instantiator = unpickedNameInstantiators[objectName] {
            return instantiator.initializeInstance(object: object, arguments: arguments)
        } else if var dict = object.dict, let argDict = arguments.dict {
            for (key, value) in argDict {
                dict[key] = value
            }
            return .dict(dict)
        }
        return object
    }
    
    struct Constants {
        static let moduleDivider = "||"
    }
}
