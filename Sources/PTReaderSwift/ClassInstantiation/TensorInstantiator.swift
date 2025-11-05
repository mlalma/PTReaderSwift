import Foundation
import MLX
import MLXUtilsLibrary

final class TensorInstantiator: Instantiator {
  init() {}
  
  func createInstance(className: String) -> UnpicklerValue {
    return .object((MLXArray(), Constants.typeName))
  }
  
  /// This is actually `torch._utils._rebuild_tensor_v2` handling
  func initializeInstance(object: UnpicklerValue, arguments: UnpicklerValue) -> UnpicklerValue {
    // storage, storage_offset, size, requires_grad, backward_hooks are the sent value
    guard let argumentList = arguments.list, argumentList.count >= 3,
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
    
    guard let _ = object.objectType(MLXArray.self) else {
      logPrint("\(object) is not a Tensor")
      return object
    }
    
    return .object((MLXArray(storage, shape, dtype: storageDType), Constants.typeName))
  }
  
  var recognizedClassNames: [String] {
    Constants.classNames
  }
  
  var unpickledTypeNames: [String] { [Constants.typeName] }
    
  struct Constants {
    static let typeName = "Tensor"
    static let classNames = [
      "torch._utils" + InstanceFactory.Constants.moduleDivider + "_rebuild_tensor_v2"
    ]
  }
}

