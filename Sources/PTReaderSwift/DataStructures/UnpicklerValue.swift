import Foundation
import MLX

/// Represents different types that can be stored to stack during unpickling.
/// **NOTE:** Once you have passed value to `UnpicklerValue` do not modify it anymore!
enum UnpicklerValue: @unchecked Sendable {
  case none
  case bool(Bool)
  case int(Int)
  case float(Double)
  case string(String)
  case bytes(Data)
  case list([UnpicklerValue])
  case dict([AnyHashable: Any])
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
      case .list(let value): return value
      case .dict(let value): return value
      case .tuple(let value): return value
      case .set(let value): return value
      // Should not appear in final output
      case .mark: return "MARK"
      case .object(let value): return value
      case .any(let value): return value
    }
  }
}

/// Utility methods to extract values more quickly
extension UnpicklerValue {
  var string: String? { if case .string(let value) = self { return value } else { return nil } }
  var int: Int? { if case .int(let value) = self { return value } else { return nil } }
  var object: (Any, String)? { if case .object(let value) = self { return value } else { return nil } }
  var objectName: String? { object?.1 }
  func objectType<T>(_ type: T.Type) -> T? { object?.0 as? T }
  var bool: Bool? { if case .bool(let value) = self { return value } else { return nil} }
  var list: [UnpicklerValue]? {
    switch self {
    case .list(let value), .tuple(let value): return value
    default: return nil
    }
  }
  var dict: [AnyHashable: Any]? { if case .dict(let value) = self { return value } else { return nil } }
  
  var dtype: DType? {
    guard let className = objectName else { return nil }
    
    switch className {
      case "DoubleStorage": return .float64
      case "FloatStorage": return .float32
      case "HalfStorage": return .float16
      case "LongStorage": return .int64
      case "IntStorage": return .int32
      case "ShortStorage": return .int16
      case "CharStorage": return .int8
      case "ByteStorage": return .uint8
      case "BoolStorage": return .bool
      case "BFloat16Storage": return .bfloat16
      case "ComplexDoubleStorage": return nil
      case "CompleteFloatStorage": return .complex64
      case "QUInt8Storage": return nil
      case "QInt8Storage": return nil
      case "QInt32Storage": return nil
      case "QUInt4x2Storage": return nil
      case "QUInt2x4Storage": return nil
      default: return nil
    }
  }
}
