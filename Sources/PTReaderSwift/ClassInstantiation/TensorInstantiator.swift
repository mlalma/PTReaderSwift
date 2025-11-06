import Foundation
import MLX
internal import MLXUtilsLibrary

/// Instantiator for PyTorch tensor objects, converting them to MLX arrays.
final class TensorInstantiator: Instantiator {
    
    init() {}
    
    /// Creates an empty MLXArray instance.
    func createInstance(className: String) -> UnpicklerValue {
        return .object((MLXArray(), Constants.typeName))
    }
    
    /// Rebuilds a tensor from PyTorch's `_rebuild_tensor_v2` arguments.
    func initializeInstance(object: UnpicklerValue, arguments: UnpicklerValue) -> UnpicklerValue {
        guard let argumentList = arguments.list,
              argumentList.count >= 3,
              let storage = argumentList[0].objectType(Data.self),
              let storageDType = argumentList[0].dtype,
              let shapeList = argumentList[2].list else {
            logPrint("Could not parse argument list \(arguments) for object \(object)")
            return object
        }
        
        let shape = shapeList.compactMap { $0.int }
        guard shape.count == shapeList.count else {
            logPrint("Could not parse shape from the arguments list \(arguments)")
            return object
        }
        
        guard object.objectType(MLXArray.self) != nil else {
            logPrint("\(object) is not a Tensor")
            return object
        }
        
        return .object((MLXArray(storage, shape, dtype: storageDType), Constants.typeName))
    }
    
    var recognizedClassNames: [String] {
        Constants.classNames
    }
    
    var unpickledTypeNames: [String] {
        [Constants.typeName]
    }
    
    struct Constants {
        static let typeName = "Tensor"
        static let classNames = [
            "torch._utils" + InstanceFactory.Constants.moduleDivider + "_rebuild_tensor_v2"
        ]
    }
}

