import Foundation

/// Supported pickle opcodes.
struct PickleOpcode {
  /// Opcodes for protocol versions 0 and 1.

  /// Push special markobject on stack
  static let mark: UInt8 = 0x28
  /// Every pickle stream ends with STOP
  static let stop: UInt8 = 0x2e
  /// Discard topmost stack item
  static let pop: UInt8 = 0x30
  /// Discard stack top through topmost markobject
  static let popMark: UInt8 = 0x31
  /// Duplicate top stack item
  static let dup: UInt8 = 0x32
  /// Push float object
  static let float: UInt8 = 0x46
  /// Push integer or bool
  static let int: UInt8 = 0x49
  /// Push four-byte signed int
  static let binInt: UInt8 = 0x4a
  /// Push 1-byte unsigned int
  static let binInt1: UInt8 = 0x4b
  /// Push long
  static let long: UInt8 = 0x4c
  /// Push 2-byte unsigned int
  static let binInt2: UInt8 = 0x4d
  /// Push None
  static let none: UInt8 = 0x4e
  /// Push persistent object
  static let persId: UInt8 = 0x50
  /// Push persistent object
  static let binPersId: UInt8 = 0x51
  /// Apply callable to argtuple
  static let reduce: UInt8 = 0x52
  /// Push string
  static let string: UInt8 = 0x53
  /// Push string
  static let binString: UInt8 = 0x54
  /// Push string (< 256 bytes)
  static let shortBinString: UInt8 = 0x55
  /// Push Unicode string
  static let unicode: UInt8 = 0x56
  /// Push Unicode string
  static let binUnicode: UInt8 = 0x58
  /// Append stack top to list
  static let append: UInt8 = 0x61
  /// Restores the object's state
  static let build: UInt8 = 0x62
  /// Finds and creates an object
  static let global: UInt8 = 0x63
  /// Build a dictionary from stack items
  static let dict: UInt8 = 0x64
  /// Push empty dictionaty
  static let emptyDict: UInt8 = 0x7d
  /// Extend list on stack
  static let appends: UInt8 = 0x65
  /// Push item from memo on stack
  static let get: UInt8 = 0x67
  /// Push item from memo on stack
  static let binGet: UInt8 = 0x68
  /// Build & push class instance
  static let inst: UInt8 = 0x69
  /// Push item from memo on stack
  static let longBinGet: UInt8 = 0x6a
  /// Build list from topmost stack items
  static let list: UInt8 = 0x6c
  /// Push empty list
  static let emptyList: UInt8 = 0x5d
  /// Build & push class instance
  static let obj: UInt8 = 0x6f
  /// Store stack top in memo
  static let put: UInt8 = 0x70
  /// Store stack top in memo
  static let binPut: UInt8 = 0x71
  /// Store stack top in memo
  static let longBinPut: UInt8 = 0x72
  /// Add key+value pair to dict
  static let setItem: UInt8 = 0x73
  /// Build tuple from topmost stack items
  static let tuple: UInt8 = 0x74
  /// Push empty tuple
  static let emptyTuple: UInt8 = 0x29
  /// Modify dict by adding topmost key+value pairs
  static let setItems: UInt8 = 0x75
  /// Push float
  static let binFloat: UInt8 = 0x47
  
  /// Extra Opcodes for protocol version 2.

  /// Identify pickle protocol
  static let proto: UInt8 = 0x80
  /// Build object by applying cls.__new__ to argtuple
  static let newObj: UInt8  = 0x81
  /// push object from extension registry; 1-byte index
  static let ext1: UInt8 = 0x82
  /// Ditto, but 2-byte index
  static let ext2: UInt8 = 0x83
  /// Ditto, but 4-byte index
  static let ext4: UInt8 = 0x84
  /// Build 1-tuple from stack top
  static let tuple1: UInt8 = 0x85
  /// Build 2-tuple from two topmost stack items
  static let tuple2: UInt8 = 0x86
  /// Build 3-tuple from three topmost stack items
  static let tuple3: UInt8 = 0x87
  /// Push True
  static let newTrue: UInt8 = 0x88
  /// Push False
  static let newFalse: UInt8  = 0x89
  /// Push long from < 256 bytes
  static let long1: UInt8 = 0x8a
  /// Push really big long
  static let long4: UInt8 = 0x8b
  
  /// Extra opcodes for protocol version 3.

  /// Push bytes
  static let binBytes: UInt8 = 0x42
  /// Push bytes (< 256 bytes)
  static let shortBinBytes: UInt8 = 0x43
  
  /// Extra opcodes for protocol version 4.

  /// Push short string; UTF-8 length < 256 bytes
  static let shortBinUnicode: UInt8 = 0x8c
  /// Push very long string
  static let binUnicode8: UInt8 = 0x8d
  /// Push very long bytes string
  static let binBytes8: UInt8 = 0x8e
  /// Push empty set on the stack
  static let emptySet: UInt8 = 0x8f
  /// Modify set by adding topmost stack items
  static let addItems: UInt8 = 0x90
  /// Build (immutable) set from topmost stack items
  static let frozenSet: UInt8 = 0x91
  /// Like NEWOBJ but work with keyword only arguments
  static let newObjEx: UInt8 = 0x92
  /// Same as GLOBAL but using names on the stacks
  static let stackGlobal: UInt8 = 0x93
  /// Store top of the stack in memo
  static let memoize: UInt8 = 0x94
  /// Indicate the beginning of a new frame
  static let frame: UInt8 = 0x95
  
  /// Extra opcodes for protocol version 5.

  /// Push bytearray
  static let byteArray8: UInt8 = 0x96
  /// Push next out-of-band buffer
  static let nextBuffer: UInt8 = 0x97
  /// Make top of stack readonly
  static let readonlyBuffer: UInt8 = 0x98
}

/// Represents different types that can be stored during unpickling
enum UnpicklerValue {
  case none
  case bool(Bool)
  case int(Int)
  case int64(Int64)
  case float(Double)
  case string(String)
  case bytes(Data)
  case list([UnpicklerValue])
  case dict([AnyHashable: UnpicklerValue])
  case tuple([UnpicklerValue])
  case set(Set<AnyHashable>)
  case mark
  case any(Any)
  
  /// Convert to Any for final output
  func toAny() -> Any {
    switch self {
    case .none: return NSNull()
    case .bool(let v): return v
    case .int(let v): return v
    case .int64(let v): return v
    case .float(let v): return v
    case .string(let v): return v
    case .bytes(let v): return v
    case .list(let v): return v.map { $0.toAny() }
    case .dict(let v): return v.mapValues { $0.toAny() }
    case .tuple(let v): return v.map { $0.toAny() }
    case .set(let v): return v
    // Should not appear in final output
    case .mark: return "MARK"
    case .any(let v): return v
    }
  }
}

/// Swift port of Python's Unpickler class for reading pickle files.
/// Pickle is Python’s built-in, Python-specific binary serialization format to turn Python objecs into a byte stream and back.
/// This class is not focused on full compatibilty, but the required subset for loading PyTorch's .pt files that use pickle to store data.
final class Unpickler {
  /// How to decode 8-bit string instances pickled by Python 2
  enum PickledCompatiblityEncoding {
    case bytes
    case ascii
    case utf8
  }
  
  /// File reading functions
  private let fileRead: (Int) -> Data
  private let fileReadline: () -> Data
  /// Encoding settings
  private let encoding: PickledCompatiblityEncoding

  /// Unpickler state
  private var unframer: Unframer!
  private var stack: [UnpicklerValue] = []
  private var metastack: [[UnpicklerValue]] = []
  private var memo: [Int: UnpicklerValue] = [:]
  private var proto: Int = 0
    
  /// Buffers for protocol version 5
  private var buffers: AnyIterator<Any>?
  /// Return value when STOP is found
  private var returnValue: Any?
  /// Flag to set for jumping out of the reading loop
  private var stopReading: Bool = false
  
  private struct Constants {
    /// Highest supported protocol
    static let highestSupportedProtocolVersion = 5
  }
  
  /// Cosntructor.
  /// - Parameters:
  ///   - fileRead: Closure that reads n bytes
  ///   - fileReadline: Closure that reads a line
  ///   - fixImports: Whether to fix Python 2/3 compatibility
  ///   - encoding: Encoding for string objects
  ///   - errors: Error handling mode
  ///   - buffers: Iterator for out-of-band buffers (protocol 5)
  init(
    fileRead: @escaping (Int) -> Data,
    fileReadline: @escaping () -> Data,
    encoding: PickledCompatiblityEncoding = .ascii,
    buffers: AnyIterator<Any>? = nil
  ) {
    self.fileRead = fileRead
    self.fileReadline = fileReadline
    self.encoding = encoding
    self.buffers = buffers
  }
    
  /// Convenience initializer for FileHandle
  convenience init(
    fileHandle: FileHandle,
    encoding: PickledCompatiblityEncoding = .ascii,
    buffers: AnyIterator<Any>? = nil
  ) {
    self.init(
      fileRead: { count in
        (try? fileHandle.readExactly(count)) ?? Data()
      },
      fileReadline: {
        fileHandle.readLine()
      },
      encoding: encoding,
      buffers: buffers
    )
  }
    
  /// Main load method. Reads a pickled object representation from the file
  /// - Returns: The reconstituted object
  /// - Throws: Any error during deserialization
  func load() throws -> Any? {
    // This is one-and-done. Return the parsed value object if we have already parsed it
    guard !stopReading else {
      return returnValue
    }
    
    // Initialize the unframer
    unframer = Unframer(
        readFromResource: fileRead,
        readLineFromResource: fileReadline
    )
    
    // Start from resetting thestate
    stack = []
    metastack = []
    proto = 0
    stopReading = false
    returnValue = nil
    
    // Main dispatch loop
    while !stopReading {
      let key = try read(1)
      if key.isEmpty {
          throw UnpicklingError.eof
      }
      
      let opcode = key[0]
      try dispatchOpcode(opcode)
    }
          
    return returnValue
  }
      
    /// Dispatch an opcode to its handler
    private func dispatchOpcode(_ opcode: UInt8) throws {
        switch opcode {
        // Basic types
        case PickleOpcode.proto: try loadProto()
        case PickleOpcode.frame: try loadFrame()
        case PickleOpcode.persId: try loadPersid()
        case PickleOpcode.binPersId: try loadBinpersid()
        case PickleOpcode.none: try loadNone()
        case PickleOpcode.newFalse: try loadFalse()
        case PickleOpcode.newTrue: try loadTrue()
        
        // Integers
        case PickleOpcode.int: try loadInt()
        case PickleOpcode.binInt: try loadBinint()
        case PickleOpcode.binInt1: try loadBinint1()
        case PickleOpcode.binInt2: try loadBinint2()
        case PickleOpcode.long: try loadLong()
        case PickleOpcode.long1: try loadLong1()
        case PickleOpcode.long4: try loadLong4()
        
        // Floats
        case PickleOpcode.float: try loadFloat()
        case PickleOpcode.binFloat: try loadBinfloat()
        
        // Strings
        case PickleOpcode.string: try loadString()
        case PickleOpcode.binString: try loadBinstring()
        case PickleOpcode.shortBinString: try loadShortBinstring()
        
        // Bytes
        case PickleOpcode.binBytes: try loadBinbytes()
        case PickleOpcode.shortBinBytes: try loadShortBinbytes()
        case PickleOpcode.binBytes8: try loadBinbytes8()
        
        // Unicode
        case PickleOpcode.unicode: try loadUnicode()
        case PickleOpcode.binUnicode: try loadBinunicode()
        case PickleOpcode.shortBinUnicode: try loadShortBinunicode()
        case PickleOpcode.binUnicode8: try loadBinunicode8()
        
        // Tuples
        case PickleOpcode.emptyTuple: try loadEmptyTuple()
        case PickleOpcode.tuple1: try loadTuple1()
        case PickleOpcode.tuple2: try loadTuple2()
        case PickleOpcode.tuple3: try loadTuple3()
        case PickleOpcode.tuple: try loadTuple()
        
        // Lists
        case PickleOpcode.emptyList: try loadEmptyList()
        case PickleOpcode.list: try loadList()
        
        // Dicts
        case PickleOpcode.emptyDict: try loadEmptyDict()
        case PickleOpcode.dict: try loadDict()
        
        // Sets
        case PickleOpcode.emptySet: try loadEmptySet()
        case PickleOpcode.frozenSet: try loadFrozenset()
        
        // Memo operations
        case PickleOpcode.get: try loadGet()
        case PickleOpcode.binGet: try loadBinget()
        case PickleOpcode.longBinGet: try loadLongBinget()
        case PickleOpcode.put: try loadPut()
        case PickleOpcode.binPut: try loadBinput()
        case PickleOpcode.longBinPut: try loadLongBinput()
        case PickleOpcode.memoize: try loadMemoize()
        
        // Container operations
        case PickleOpcode.append: try loadAppend()
        case PickleOpcode.appends: try loadAppends()
        case PickleOpcode.setItem: try loadSetitem()
        case PickleOpcode.setItems: try loadSetitems()
        case PickleOpcode.addItems: try loadAdditems()
        case PickleOpcode.build: try loadBuild()
        
        // Stack operations
        case PickleOpcode.mark: try loadMark()
        case PickleOpcode.pop: try loadPop()
        case PickleOpcode.popMark: try loadPopMark()
        case PickleOpcode.dup: try loadDup()
        
        // Object construction
        case PickleOpcode.reduce: try loadReduce()
        case PickleOpcode.newObj: try loadNewobj()
        case PickleOpcode.newObjEx: try loadNewobjEx()
        case PickleOpcode.global: try loadGlobal()
        case PickleOpcode.stackGlobal: try loadStackGlobal()
        case PickleOpcode.inst: try loadInst()
        case PickleOpcode.obj: try loadObj()
        
        // Extensions
        case PickleOpcode.ext1: try loadExt1()
        case PickleOpcode.ext2: try loadExt2()
        case PickleOpcode.ext4: try loadExt4()
        
        // Protocol 5
        case PickleOpcode.byteArray8: try loadBytearray8()
        case PickleOpcode.nextBuffer: try loadNextBuffer()
        case PickleOpcode.readonlyBuffer: try loadReadonlyBuffer()
        
        // Control
        case PickleOpcode.stop: try loadStop()
        
        default:
            throw UnpicklingError.error("Unknown opcode: \(opcode)")
        }
    }
    
    // MARK: - Helper Methods
    
    /// Read n bytes from the unframer
    private func read(_ n: Int) throws -> Data {
        return try unframer.read(n)
    }
    
    /// Read a line from the unframer
    private func readline() throws -> Data {
        return try unframer.readline()
    }
    
    /// Read into a buffer
    private func readinto(_ buffer: inout Data) throws -> Int {
        return try unframer.readInto(&buffer)
    }
    
    /// Append a value to the stack
    private func append(_ value: UnpicklerValue) {
        stack.append(value)
    }
    
    /// Pop and return items from the stack after the last MARK
    private func popMark() -> [UnpicklerValue] {
        let items = stack
        stack = metastack.popLast() ?? []
        return items
    }
    
    /// Handle persistent load (can be overridden by subclasses)
    func persistentLoad(_ pid: Any) throws -> UnpicklerValue {
        throw UnpicklingError.unsupportedPersistentId
    }
    
    /// Find a class by module and name (can be overridden by subclasses)
    func findClass(module: String, name: String) throws -> UnpicklerValue {
        // For now, return a placeholder
        // In a real implementation, this would need reflection/dynamic loading
        return .dict(["__module__": .string(module), "__name__": .string(name)])
    }
    
    // MARK: - Dispatch Methods
    
    private func loadProto() throws {
        let protoData = try read(1)
        let proto = Int(protoData[0])
      if proto < 0 || proto > Constants.highestSupportedProtocolVersion {
            throw UnpicklingError.unsupportedProtocol(proto)
        }
        self.proto = proto
    }
    
    private func loadFrame() throws {
        let sizeData = try read(8)
        let frameSize = sizeData.withUnsafeBytes { $0.load(as: UInt64.self) }
        
        if frameSize > Int.max {
            throw UnpicklingError.exceedsMaxSize
        }
        
        try unframer.loadFrame(frameSize: Int(frameSize))
    }
    
    private func loadPersid() throws {
        let line = try readline()
        guard let pidString = String(data: line.dropLast(), encoding: .ascii) else {
            throw UnpicklingError.error("persistent IDs in protocol 0 must be ASCII strings")
        }
        let value = try persistentLoad(pidString)
        append(value)
    }
    
    private func loadBinpersid() throws {
        let pid = stack.removeLast()
        let value = try persistentLoad(pid.toAny())
        append(value)
    }
    
    private func loadNone() throws {
        append(.none)
    }
    
    private func loadFalse() throws {
        append(.bool(false))
    }
    
    private func loadTrue() throws {
        append(.bool(true))
    }
    
    private func loadInt() throws {
        let data = try readline()
        let line = data.dropLast()  // Remove newline
        
        // Check for special boolean values
        if line.elementsEqual([0x30, 0x30]) {  // "00"
            append(.bool(false))
        } else if line.elementsEqual([0x30, 0x31]) {  // "01"
            append(.bool(true))
        } else {
            guard let str = String(data: line, encoding: .ascii),
                  let val = Int(str, radix: 0) else {
                throw UnpicklingError.error("Invalid integer format")
            }
            append(.int(val))
        }
    }
    
    private func loadBinint() throws {
        let data = try read(4)
        let value = data.withUnsafeBytes { $0.load(as: Int32.self) }
        append(.int(Int(value)))
    }
    
    private func loadBinint1() throws {
        let data = try read(1)
        append(.int(Int(data[0])))
    }
    
    private func loadBinint2() throws {
        let data = try read(2)
        let value = data.withUnsafeBytes { $0.load(as: UInt16.self) }
        append(.int(Int(value)))
    }
    
    private func loadLong() throws {
        let data = try readline()
        var line = data.dropLast()  // Remove newline
        
        // Remove trailing 'L' if present
        if line.last == UInt8(ascii: "L") {
            line = line.dropLast()
        }
        
        guard let str = String(data: line, encoding: .ascii),
              let val = Int(str, radix: 0) else {
            throw UnpicklingError.error("Invalid long format")
        }
        append(.int(val))
    }
    
    private func loadLong1() throws {
        let lenData = try read(1)
        let n = Int(lenData[0])
        let data = try read(n)
        let value = decodeLong(data)
        append(.int(value))
    }
    
    private func loadLong4() throws {
        let lenData = try read(4)
        let n = lenData.withUnsafeBytes { $0.load(as: Int32.self) }
        
        if n < 0 {
            throw UnpicklingError.negativeByteCount
        }
        
        let data = try read(Int(n))
        let value = decodeLong(data)
        append(.int(value))
    }
    
    private func loadFloat() throws {
        let data = try readline()
        let line = data.dropLast()  // Remove newline
        
        guard let str = String(data: line, encoding: .ascii),
              let val = Double(str) else {
            throw UnpicklingError.error("Invalid float format")
        }
        append(.float(val))
    }
    
    private func loadBinfloat() throws {
        let data = try read(8)
        let value = data.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) -> Double in
            let bytes = ptr.load(as: UInt64.self)
            let bigEndianBytes = UInt64(bigEndian: bytes)
            return Double(bitPattern: bigEndianBytes)
        }
        append(.float(value))
    }
    
    private func decodeString(_ value: Data) throws -> String {
      if encoding == .bytes {
            // Return as string representation of bytes
            return value.map { String(format: "%02x", $0) }.joined()
        } else {
          let enc = encoding == .ascii ? String.Encoding.ascii : .utf8
            guard let str = String(data: value, encoding: enc) else {
                throw UnpicklingError.error("Failed to decode string")
            }
            return str
        }
    }
    
    private func loadString() throws {
        var data = try readline()
        data = data.dropLast()  // Remove newline
        
        // Strip outermost quotes
        if data.count >= 2 && (data.first == data.last) &&
           (data.first == UInt8(ascii: "\"") || data.first == UInt8(ascii: "'")) {
            data = data.dropFirst().dropLast()
        } else {
            throw UnpicklingError.error("STRING opcode argument must be quoted")
        }
        
        let str = try decodeString(data)
        append(.string(str))
    }
    
    private func loadBinstring() throws {
        let lenData = try read(4)
        let len = lenData.withUnsafeBytes { $0.load(as: Int32.self) }
        
        if len < 0 {
            throw UnpicklingError.negativeByteCount
        }
        
        let data = try read(Int(len))
        let str = try decodeString(data)
        append(.string(str))
    }
    
    private func loadShortBinstring() throws {
        let lenData = try read(1)
        let len = Int(lenData[0])
        let data = try read(len)
        let str = try decodeString(data)
        append(.string(str))
    }
    
    private func loadBinbytes() throws {
        let lenData = try read(4)
        let len = lenData.withUnsafeBytes { $0.load(as: UInt32.self) }
        
        if len > Int.max {
            throw UnpicklingError.exceedsMaxSize
        }
        
        let data = try read(Int(len))
        append(.bytes(data))
    }
    
    private func loadShortBinbytes() throws {
        let lenData = try read(1)
        let len = Int(lenData[0])
        let data = try read(len)
        append(.bytes(data))
    }
    
    private func loadBinbytes8() throws {
        let lenData = try read(8)
        let len = lenData.withUnsafeBytes { $0.load(as: UInt64.self) }
        
        if len > Int.max {
            throw UnpicklingError.exceedsMaxSize
        }
        
        let data = try read(Int(len))
        append(.bytes(data))
    }
    
    private func loadUnicode() throws {
        let data = try readline()
        let line = data.dropLast()  // Remove newline
        
        // Decode raw-unicode-escape
        guard let str = String(data: line, encoding: .utf8) else {
            throw UnpicklingError.error("Failed to decode unicode")
        }
        append(.string(str))
    }
    
    private func loadBinunicode() throws {
        let lenData = try read(4)
        let len = lenData.withUnsafeBytes { $0.load(as: UInt32.self) }
        
        if len > Int.max {
            throw UnpicklingError.exceedsMaxSize
        }
        
        let data = try read(Int(len))
        guard let str = String(data: data, encoding: .utf8) else {
            throw UnpicklingError.error("Failed to decode unicode")
        }
        append(.string(str))
    }
    
    private func loadShortBinunicode() throws {
        let lenData = try read(1)
        let len = Int(lenData[0])
        let data = try read(len)
        guard let str = String(data: data, encoding: .utf8) else {
            throw UnpicklingError.error("Failed to decode unicode")
        }
        append(.string(str))
    }
    
    private func loadBinunicode8() throws {
        let lenData = try read(8)
        let len = lenData.withUnsafeBytes { $0.load(as: UInt64.self) }
        
        if len > Int.max {
            throw UnpicklingError.exceedsMaxSize
        }
        
        let data = try read(Int(len))
        guard let str = String(data: data, encoding: .utf8) else {
            throw UnpicklingError.error("Failed to decode unicode")
        }
        append(.string(str))
    }
    
    private func loadEmptyTuple() throws {
        append(.tuple([]))
    }
    
    private func loadTuple1() throws {
        let item = stack.removeLast()
        append(.tuple([item]))
    }
    
    private func loadTuple2() throws {
        let item2 = stack.removeLast()
        let item1 = stack.removeLast()
        append(.tuple([item1, item2]))
    }
    
    private func loadTuple3() throws {
        let item3 = stack.removeLast()
        let item2 = stack.removeLast()
        let item1 = stack.removeLast()
        append(.tuple([item1, item2, item3]))
    }
    
    private func loadTuple() throws {
        let items = popMark()
        append(.tuple(items))
    }
    
    private func loadEmptyList() throws {
        append(.list([]))
    }
    
    private func loadList() throws {
        let items = popMark()
        append(.list(items))
    }
    
    private func loadEmptyDict() throws {
        append(.dict([:]))
    }
    
    private func loadDict() throws {
        let items = popMark()
        var dict: [AnyHashable: UnpicklerValue] = [:]
        
        var i = 0
        while i < items.count - 1 {
            let key = items[i].toAny() as! AnyHashable
            let value = items[i + 1]
            dict[key] = value
            i += 2
        }
        
        append(.dict(dict))
    }
    
    private func loadEmptySet() throws {
        append(.set(Set()))
    }
    
    private func loadFrozenset() throws {
        let items = popMark()
        let hashableItems = items.map { $0.toAny() as! AnyHashable }
        append(.set(Set(hashableItems)))
    }
    
    private func loadGet() throws {
        let data = try readline()
        let line = data.dropLast()  // Remove newline
        
        guard let str = String(data: line, encoding: .ascii),
              let i = Int(str) else {
            throw UnpicklingError.error("Invalid GET index")
        }
        
        guard let value = memo[i] else {
            throw UnpicklingError.memoNotFound(i)
        }
        
        append(value)
    }
    
    private func loadBinget() throws {
        let data = try read(1)
        let i = Int(data[0])
        
        guard let value = memo[i] else {
            throw UnpicklingError.memoNotFound(i)
        }
        
        append(value)
    }
    
    private func loadLongBinget() throws {
        let data = try read(4)
        let i = data.withUnsafeBytes { $0.load(as: UInt32.self) }
        
        guard let value = memo[Int(i)] else {
            throw UnpicklingError.memoNotFound(Int(i))
        }
        
        append(value)
    }
    
    private func loadPut() throws {
        let data = try readline()
        let line = data.dropLast()  // Remove newline
        
        guard let str = String(data: line, encoding: .ascii),
              let i = Int(str) else {
            throw UnpicklingError.error("Invalid PUT index")
        }
        
        if i < 0 {
            throw UnpicklingError.negativeArgument
        }
        
        memo[i] = stack.last!
    }
    
    private func loadBinput() throws {
        let data = try read(1)
        let i = Int(data[0])
        
        if i < 0 {
            throw UnpicklingError.negativeArgument
        }
        
        memo[i] = stack.last!
    }
    
    private func loadLongBinput() throws {
        let data = try read(4)
        let i = data.withUnsafeBytes { $0.load(as: UInt32.self) }
        
        if i > Int.max {
            throw UnpicklingError.negativeArgument
        }
        
        memo[Int(i)] = stack.last!
    }
    
    private func loadMemoize() throws {
        let idx = memo.count
        memo[idx] = stack.last!
    }
    
    private func loadAppend() throws {
        let value = stack.removeLast()
        if case .list(var list) = stack.removeLast() {
            list.append(value)
            append(.list(list))
        } else {
            throw UnpicklingError.error("APPEND requires a list")
        }
    }
    
    private func loadAppends() throws {
        let items = popMark()
        if case .list(var list) = stack.removeLast() {
            list.append(contentsOf: items)
            append(.list(list))
        } else {
            throw UnpicklingError.error("APPENDS requires a list")
        }
    }
    
    private func loadSetitem() throws {
        let value = stack.removeLast()
        let key = stack.removeLast()
        
        if case .dict(var dict) = stack.removeLast() {
            dict[key.toAny() as! AnyHashable] = value
            append(.dict(dict))
        } else {
            throw UnpicklingError.error("SETITEM requires a dict")
        }
    }
    
    private func loadSetitems() throws {
        let items = popMark()
        
        if case .dict(var dict) = stack.removeLast() {
            var i = 0
            while i < items.count - 1 {
                let key = items[i].toAny() as! AnyHashable
                let value = items[i + 1]
                dict[key] = value
                i += 2
            }
            append(.dict(dict))
        } else {
            throw UnpicklingError.error("SETITEMS requires a dict")
        }
    }
    
    private func loadAdditems() throws {
        let items = popMark()
        
        if case .set(var set) = stack.removeLast() {
            for item in items {
                set.insert(item.toAny() as! AnyHashable)
            }
            append(.set(set))
        } else {
            throw UnpicklingError.error("ADDITEMS requires a set")
        }
    }
    
    private func loadBuild() throws {
        // Simplified BUILD implementation
        // In a full implementation, this would handle __setstate__ and __dict__ updates
        let _ = stack.removeLast()  // state
        // inst stays on stack
    }
    
    private func loadMark() throws {
        metastack.append(stack)
        stack = []
    }
    
    private func loadPop() throws {
        if !stack.isEmpty {
            stack.removeLast()
        } else {
            _ = popMark()
        }
    }
    
    private func loadPopMark() throws {
        _ = popMark()
    }
    
    private func loadDup() throws {
        append(stack.last!)
    }
    
    private func loadReduce() throws {
        // Simplified REDUCE implementation
        let args = stack.removeLast()
        let _ = stack.removeLast()  // func
        
        // For now, just push a placeholder
        append(args)
    }
    
    private func loadNewobj() throws {
        let args = stack.removeLast()
        let _ = stack.removeLast()  // cls
        
        // For now, just push a placeholder
        append(args)
    }
    
    private func loadNewobjEx() throws {
        let _ = stack.removeLast()  // kwargs
        let args = stack.removeLast()
        let _ = stack.removeLast()  // cls
        
        // For now, just push a placeholder
        append(args)
    }
    
    private func loadGlobal() throws {
        let moduleLine = try readline()
        let nameLine = try readline()
        
        guard let module = String(data: moduleLine.dropLast(), encoding: .utf8),
              let name = String(data: nameLine.dropLast(), encoding: .utf8) else {
            throw UnpicklingError.error("Failed to decode GLOBAL")
        }
        
        let klass = try findClass(module: module, name: name)
        append(klass)
    }
    
    private func loadStackGlobal() throws {
        guard case .string(let name) = stack.removeLast(),
              case .string(let module) = stack.removeLast() else {
            throw UnpicklingError.error("STACK_GLOBAL requires str")
        }
        
        let klass = try findClass(module: module, name: name)
        append(klass)
    }
    
    private func loadExt1() throws {
        let data = try read(1)
        let code = Int(data[0])
        try getExtension(code: code)
    }
    
    private func loadExt2() throws {
        let data = try read(2)
        let code = data.withUnsafeBytes { $0.load(as: UInt16.self) }
        try getExtension(code: Int(code))
    }
    
    private func loadExt4() throws {
        let data = try read(4)
        let code = data.withUnsafeBytes { $0.load(as: Int32.self) }
        try getExtension(code: Int(code))
    }
    
    private func getExtension(code: Int) throws {
        if code <= 0 {
            throw UnpicklingError.error("EXT specifies code <= 0")
        }
        throw UnpicklingError.unregisteredExtension(code)
    }
    
    private func loadInst() throws {
        let moduleLine = try readline()
        let nameLine = try readline()
        
        guard let module = String(data: moduleLine.dropLast(), encoding: .ascii),
              let name = String(data: nameLine.dropLast(), encoding: .ascii) else {
            throw UnpicklingError.error("Failed to decode INST")
        }
        
        let _ = try findClass(module: module, name: name)
        let _ = popMark()
        
        // Simplified - just push a placeholder
        append(.none)
    }
    
    private func loadObj() throws {
        var args = popMark()
        let _ = args.removeFirst()  // cls
        
        // Simplified - just push a placeholder
        append(.none)
    }
    
    private func loadBytearray8() throws {
        let lenData = try read(8)
        let len = lenData.withUnsafeBytes { $0.load(as: UInt64.self) }
        
        if len > Int.max {
            throw UnpicklingError.exceedsMaxSize
        }
        
        var buffer = Data(count: Int(len))
        _ = try readinto(&buffer)
        append(.bytes(buffer))
    }
    
    private func loadNextBuffer() throws {
        guard let buffers = buffers else {
            throw UnpicklingError.error("pickle stream refers to out-of-band data but no buffers argument was given")
        }
        
        guard let buf = buffers.next() else {
            throw UnpicklingError.error("not enough out-of-band buffers")
        }
        
        append(.any(buf))
    }
    
    private func loadReadonlyBuffer() throws {
        // In Swift, we don't have the same readonly buffer concept
        // Just leave the buffer as-is on the stack
    }
    
    private func loadStop() throws {
      returnValue = stack.removeLast()
      stopReading = true
    }
    
    // MARK: - Utility Functions
    
    /// Decode a long from two's complement little-endian bytes
    private func decodeLong(_ data: Data) -> Int {
        if data.isEmpty {
            return 0
        }
        
        // Convert from little-endian two's complement
        var result = 0
        var multiplier = 1
        
        for byte in data {
            result += Int(byte) * multiplier
            multiplier *= 256
        }
        
        // Handle sign bit
        let signBit = data.last! & 0x80
        if signBit != 0 {
            // Negative number - subtract 2^(bits)
            let bits = data.count * 8
            let maxValue = 1 << bits
            result -= maxValue
        }
        
        return result
    }
}

