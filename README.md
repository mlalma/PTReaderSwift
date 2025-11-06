# .pt File Reader for Swift

*Experimental* Swift library for reading PyTorch `.pt` files and converting them to MLX arrays and dicts.

Provides an unpickling implementation that can deserialize PyTorch model files and tensors for use with Apple's MLX framework. 

Note that Python unpickling uses the language's and its runtime's features quite extensively and one-to-one implementation is impossible for Swift. 

For reading `.pt` files a somewhat robust unpickling can be built, but general purpose unpickler would be very difficult.

The implementation is very experimental and it is highly likely that you need to add new `Instantiator` implementations to create and initialize class types properly depending on the complexity of your `.pt` file.

## Requirements

- iOS 18.0+
- macOS 15.0+
- (Other Apple platforms may work as well)

## Local Installation

This repository uses Git LFS for large model files for the tests. Make sure you have Git LFS installed:

```bash
# Using Homebrew (macOS)
brew install git-lfs
git lfs install

# Clone the repository (LFS files will be downloaded automatically)
git clone https://github.com/mlalma/PTReaderSwift.git
```

The following file patterns are tracked with Git LFS:
- `*.pt` - PyTorch model files

### Swift Package Manager

Add PTReaderSwift to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/mlalma/PTReaderSwift.git", from: "0.0.1")
]
```

Then add it to your target dependencies:

```swift
targets: [
    .target(
        name: "YourTarget",
        dependencies: ["PTReaderSwift"]
    )
]
```

## Usage

### Loading a PyTorch File

```swift
import PTReaderSwift
import MLX

// Load a .pt file
let url = URL(fileURLWithPath: "path/to/model.pt")

let result = try await Task { @PTReaderActor in
    let file = try PTFile(fileName: url)
    return file.parseData()
}.value

// Extract tensor data, but it depends how the data has been
// stored to the .pt file
if let tensor = result?.objectType(MLXArray.self),
   result?.objectName == "Tensor" {
    print("Tensor shape: \(tensor.shape)")
}
```

### Using the Unpickler Directly

```swift
import PTReaderSwift
import Foundation

// Load pickle data
let data = try Data(contentsOf: url)

let result = try await Task { @PTReaderActor in
    let unpickler = Unpickler(inputData: data, persistentLoader: nil)
    return try unpickler.load()
}.value

// result contains `UnpicklerValue` that wraps the actual unpickled object
```

### Custom Object Instantiation

`PTReaderSwift` allows you to add intializing new class instances by implementing the `Instantiator` protocol:

```swift
final class CustomInstantiator: Instantiator {
    func createInstance(className: String) -> UnpicklerValue {
        // Here create your new object
        return .object((YourCustomType(), "CustomTypeName"))
    }
    
    func initializeInstance(object: UnpicklerValue, arguments: UnpicklerValue) -> UnpicklerValue {
        // Initialize your custom object with the arguments
        return object
    }
    
    var recognizedClassNames: [String] {
        // This is the Python class
        ["your.module||YourClass"]
    }
    
    var unpickledTypeNames: [String] {
        // This is going to be the name of the class on `UnpicklerValue`
        ["CustomTypeName"]
    }
}

// Register your instantiator before 
InstanceFactory.shared.addInstantiator(CustomInstantiator())
```

## Architecture

### Core Components

- **`PTFile`** - Main class for reading `.pt` files, handles ZIP archive extraction
- **`Unpickler`** - Python pickle protocol implementation
- **`UnpicklerValue`** - Type-safe representation of unpickled values
- **`InstanceFactory`** - Registry for custom object instantiators

### Built-in Instantiators

- **`TensorInstantiator`** - Converts PyTorch tensors to MLX arrays
- **`UntypedStorageInstantiator`** - Handles PyTorch storage objects, represented as `Data` objects
- **`DictInstantiator`** - Handles Python dictionaries and OrderedDict

## Examples

The `Tests/PTReaderSwiftTests` directory contains several examples:

- **Loading tensor data** - `testLoading()`
- **Unpickling custom objects** - `testUnpickling()` with Tiktoken encoding
- **Reading model files** - `testReadingBigPTFile()`

## Dependencies

PTReaderSwift relies on the following packages:

- [**mlx-swift**](https://github.com/ml-explore/mlx-swift) - Apple's MLX framework for Swift
- [**ZIPFoundation**](https://github.com/weichsel/ZIPFoundation) - ZIP archive handling
- [**MLXUtilsLibrary**](https://github.com/mlalma/MLXUtilsLibrary) - Utilities for MLX

## License

PTReaderSwift is released under the Apache License 2.0. See [LICENSE](LICENSE) for details.