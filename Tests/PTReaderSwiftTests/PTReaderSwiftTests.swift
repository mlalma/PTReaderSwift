import Foundation
import Testing
import MLXUtilsLibrary
@testable import PTReaderSwift

enum TestError: Error {
  case generalError
}

@Test func testLoading() async throws {
  guard let url = Bundle.module.url(forResource: "token_bytes", withExtension: "pt",  subdirectory: "Resources") else {
    print("Couldn't find token_bytes.pt")
    throw TestError.generalError
  }
  
  let _ = try PTFile(fileName: url)
}

@Test func testUnpickling() async throws {
  class MockReader : TensorDataLoader {
    func load(dataType: String, key: String) throws -> (Data, String) {
      return (Data(), "IntStorage")
    }
  }
  
  guard let url = Bundle.module.url(forResource: "tokenizer", withExtension: "pkl",  subdirectory: "Resources") else {
    print("Couldn't find tokenizer.pkl")
    throw TestError.generalError
  }
  
  let reader = MockReader()
  let data = try! Data.init(contentsOf: url)
  
  let unpickler = Unpickler(inputData: data, tensorLoader: reader)
  let outputData = try unpickler.load()
}
