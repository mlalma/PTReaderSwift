import Foundation
import MLX

final class TensorInstantiator: Instantiator {
  init() {}
  
  func createInstance(className: String) -> UnpicklerValue {
    return .object((MLXArray(), Constants.typeName))
  }
  
  func initializeInstance(object: UnpicklerValue, arguments: Any) {
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

