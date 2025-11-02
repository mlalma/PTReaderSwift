import Foundation

protocol Instantiator {
  func createInstance(className: String) -> UnpicklerValue
  func initializeInstance(object: UnpicklerValue, arguments: Any)
  var recognizedClassNames: [String] { get }
}

