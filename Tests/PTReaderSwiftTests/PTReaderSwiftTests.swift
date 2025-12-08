import Foundation
import Testing
import MLXUtilsLibrary
import MLX
@testable import PTReaderSwift

/// Test errors
enum TestError: Error {
  case couldNotFindResource
  case generalError
  case wrongOutputData
}

/// Test loading a small .pt file
@Test func testLoading() async throws {
  guard let url = findFile("token_bytes", "pt") else {
    logPrint("Couldn't find token_bytes.pt")
    throw TestError.couldNotFindResource
  }
    
  let outputVal = try await Task { @PTReaderActor in
    let file = try PTFile(fileName: url)
    return file.parseData()
  }.value
  
  guard let outputVal,
        let outputObject = outputVal.objectType(MLXArray.self),
        outputVal.objectName == "Tensor" else {
    throw TestError.wrongOutputData
  }
  
  #expect(outputObject.shape == [65536])
}

/// Test using just unpickling functionality
@Test func testUnpickling() async throws {
  guard let url = findFile("tokenizer", "pkl") else {
    print("Couldn't find tokenizer.pkl")
    throw TestError.couldNotFindResource
  }
  
  let data = try! Data.init(contentsOf: url)
  
  let outputVal = try await Task { @PTReaderActor in
    InstanceFactory.shared.addInstantiator(TiktokenEncodingInstantiator())
    let unpickler = Unpickler(inputData: data, persistentLoader: nil)
    return try unpickler.load()
  }.value
  
  guard let outputVal,
        let outputObject = outputVal.objectType(TiktokenEncoding.self),
        outputVal.objectName == "TiktokenEncoding" else {
    throw TestError.wrongOutputData
  }
  
  #expect(outputObject.name == "rustbpe")
  #expect(outputObject.mergeableRanks?.keys.count == 65527)
  #expect(outputObject.specialTokens?.keys.count == 9)
}

/// Test reading a bigger model file
@Test func testReadingBigPTFile() async throws {
  guard let url = findFile("model_000650", "pt") else {
    print("Couldn't find model_000650.pt")
    throw TestError.couldNotFindResource
  }
    
  let outputVal = try await Task { @PTReaderActor in
    let file = try PTFile(fileName: url)
    return file.parseData()
  }.value
  
  guard let outputVal, let unpickledDict = outputVal.dict else {
    throw TestError.wrongOutputData
  }
  
  var dict: [String: MLXArray] = [:]
  var metadata: [AnyHashable: Any]?
  
  for (key, value) in unpickledDict {
    guard let keyStr = key as? String else {
      throw TestError.wrongOutputData
    }
    
    guard keyStr != "_metadata" else {
      metadata = (value as? UnpicklerValue)?.dict as? [AnyHashable: Any]
      continue
    }
    
    guard let mlxArray = (value as? (MLXArray, String)), mlxArray.1 == "Tensor" else {
      throw TestError.wrongOutputData
    }
    
    dict[keyStr] = mlxArray.0
  }
  
  #expect(dict.keys.count == 122)
  #expect(metadata != nil)
}

@Test func loadSmallModel() async throws {
    guard let url = findFile("pytorch_model_2", "bin") else {
        print("Couldn't find pytorch_model_2.bin")
        throw TestError.couldNotFindResource
    }
        
    let outputVal = try await Task { @PTReaderActor in
      let file = try PTFile(fileName: url)
      return file.parseData()
    }.value
    
    if let outputVal, let outputDict = outputVal.dict {
        for (key, value) in outputDict {
            if let potentialArray = value as? (Any, String), potentialArray.1 == "Tensor", let mlxArray = potentialArray.0 as? MLXArray {
                print("VAL: \(type(of: value))")
            }            
        }
    }
}
