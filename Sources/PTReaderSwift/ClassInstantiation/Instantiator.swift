import Foundation

/// Protocol for creating and initializing custom objects during unpickling.
public protocol Instantiator {
    /// Creates a new instance of the specified class.
    func createInstance(className: String) -> UnpicklerValue

    /// Initializes an object with the provided arguments.
    func initializeInstance(object: UnpicklerValue, arguments: UnpicklerValue) -> UnpicklerValue    
    
    /// Python class names that this instantiator can handle.
    var recognizedClassNames: [String] { get }    
    
    /// Type names assigned to unpickled objects.
    var unpickledTypeNames: [String] { get }
}

