import Foundation

protocol Instantiator {
  func createInstance(className: String) -> UnpicklerValue
  func initializeInstance(object: UnpicklerValue, arguments: UnpicklerValue)
  var recognizedClassNames: [String] { get }
  var unpickledTypeNames: [String] { get }
}

