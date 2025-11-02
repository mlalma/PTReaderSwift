import Foundation
import MLX

final class TensorInstantiator: Instantiator {
  init() {}
  
  func createInstance(className: String) -> UnpicklerValue {
    return .object((MLXArray(), "Tensor"))
  }
  
  func initializeInstance(object: UnpicklerValue, arguments: Any) {
  }
  
  var recognizedClassNames: [String] {
    Constants.classNames
  }
    
  struct Constants {
    static let classNames = [
      "torch._utils" + InstanceFactory.Constants.moduleDivider + "_rebuild_tensor_v2"
    ]
  }
}

