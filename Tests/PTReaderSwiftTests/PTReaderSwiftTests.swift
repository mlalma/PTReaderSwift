import Foundation
import Testing
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
