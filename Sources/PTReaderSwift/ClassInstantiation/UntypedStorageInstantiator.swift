import Foundation

/// Instantiator for PyTorch untyped storage objects.
/// Creates placeholder `Data` objects for various PyTorch storage types.
final class UntypedStorageInstantiator: Instantiator {
    
    init() {}
    
    /// Creates an empty storage instance with the given class name.
    func createInstance(className: String) -> UnpicklerValue {
        return .object((Data(), className))
    }
    
    /// Returns the object unchanged as no initialization is needed.
    func initializeInstance(object: UnpicklerValue, arguments: UnpicklerValue) -> UnpicklerValue {
        object
    }
    
    var unpickledTypeNames: [String] {
        [
            "DoubleStorage", "FloatStorage", "HalfStorage", "LongStorage",
            "IntStorage", "ShortStorage", "CharStorage", "ByteStorage",
            "BoolStorage", "BFloat16Storage", "CompleteFloatStorage"
        ]
    }
    
    var recognizedClassNames: [String] {
        unpickledTypeNames.map { "torch" + InstanceFactory.Constants.moduleDivider + $0 }
    }
}

