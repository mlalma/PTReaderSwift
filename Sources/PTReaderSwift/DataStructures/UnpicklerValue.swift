import Foundation

/// Represents different types that can be stored to stack during unpickling.
enum UnpicklerValue {
  case none
  case bool(Bool)
  case int(Int)
  case float(Double)
  case string(String)
  case bytes(Data)
  case list([UnpicklerValue])
  case dict([AnyHashable: UnpicklerValue])
  case tuple([UnpicklerValue])
  case set(Set<AnyHashable>)
  case mark
  case object((Any, String))
  case any(Any)
  
  /// Convert to Any for final output
  func toAny() -> Any {
    switch self {
      case .none: return NSNull()
      case .bool(let value): return value
      case .int(let value): return value
      case .float(let value): return value
      case .string(let value): return value
      case .bytes(let value): return value
      case .list(let value): return value.map { $0.toAny() }
      case .dict(let value): return value.mapValues { $0.toAny() }
      case .tuple(let value): return value.map { $0.toAny() }
      case .set(let value): return value
      // Should not appear in final output
      case .mark: return "MARK"
      case .object(let value): return value
      case .any(let value): return value
    }
  }
}
