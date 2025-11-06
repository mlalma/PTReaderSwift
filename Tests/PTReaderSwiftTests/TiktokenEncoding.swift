import Foundation
 
/// Tiktoken data for BPE tokenizer
final class TiktokenEncoding {
  var name: String?
  var patStr: String?
  var mergeableRanks: [Data: Int]?
  var specialTokens: [String: Int]?
}
