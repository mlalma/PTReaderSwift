import Foundation
import Testing
import MLXUtilsLibrary
@testable import PTReaderSwift

enum TestError: Error {
  case couldNotFindResource
  case generalError
}

@Test func testLoading() async throws {
  guard let url = findFile("token_bytes", "pt") else {
    logPrint("Couldn't find token_bytes.pt")
    throw TestError.couldNotFindResource
  }
    
  let val = await Task { @PTReaderActor in
    let file = try PTFile(fileName: url)
    return file.parsedData
  }.result
  
  // TODO: Write #expect checks
  print(val)
}

@Test func testUnpickling() async throws {
  guard let url = findFile("tokenizer", "pkl") else {
    print("Couldn't find tokenizer.pkl")
    throw TestError.couldNotFindResource
  }
  
  let data = try! Data.init(contentsOf: url)
  
  let outputVal = await Task { @PTReaderActor in
    InstanceFactory.shared.addInstantiator(TiktokenEncodingInstantiator())
    let unpickler = Unpickler(inputData: data, persistentLoader: nil)
    return try unpickler.load()
  }.result
  
  // TODO: Write #expect checks
  print(outputVal)
}

@Test func testReadingBigPTFile() async throws {
  guard let url = findFile("model_000650", "pt") else {
    print("Couldn't find model_000650.pt")
    throw TestError.couldNotFindResource
  }
  
  debugArchive(url: url)
  
  let val = await Task { @PTReaderActor in
    let file = try PTFile(fileName: url)
    return file.parsedData
  }.result
  
  // TODO: Write #expect checks
  print(val)
}
