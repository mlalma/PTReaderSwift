import Foundation
import MLX
import MLXUtilsLibrary

/// Swift port of Python's Unpickler class for reading pickle files.
/// Pickle is Python’s built-in, Python-specific binary serialization format to turn Python objecs into a byte stream and back.
/// This class is not focused on full compatibilty, but the required subset for loading PyTorch's .pt files that use pickle to store data.
/// During unpickiing there is a tiny stack-based virtual machine (VM) interpreting opcodes from the binary stream to rebuild the object graph.
/// Available Python objects are mapped to Swift objects where possible.
@PTReaderActor
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
  /// Persistent loader routine
  private weak var persistentLoader: UnpicklerPersistentLoader?

  /// Unpickler state
  private var unframer: Unframer!
  private var stack: [UnpicklerValue] = []
  private var metastack: [[UnpicklerValue]] = []
  private var memo: [Int: UnpicklerValue] = [:]
  private var invertedRegistry: [Int: (String, String)] = [:]
  
  /// Protocol version of the unpickled stream
  private var proto: Int = 0
    
  /// Buffers for protocol version 5
  private var buffers: AnyIterator<Any>?
  /// Return value when STOP is found
  private var returnValue: UnpicklerValue?
  /// Flag to set for jumping out of the reading loop
  private var stopReading: Bool = false
  
  private struct Constants {
    /// Highest supported protocol
    static let highestSupportedProtocolVersion = 5
    /// End-of-line marker when unpickling strings
    static let endOfLineMarker = UInt8(ascii: "\n")
  }
  
  #if DEBUG
  var dispatchCounter = 0
  #endif
  
  /// Constructor.
  /// - Parameters:
  ///   - fileRead: Closure that reads n bytes
  ///   - fileReadline: Closure that reads a line
  ///   - persistentLoader: Loader functionality for persistent load
  ///   - encoding: Encoding for string objects
  ///   - buffers: Iterator for out-of-band buffers (protocol 5)
  init(
    fileRead: @escaping (Int) -> Data,
    fileReadline: @escaping () -> Data,
    persistentLoader: UnpicklerPersistentLoader?,
    encoding: PickledCompatiblityEncoding = .ascii,
    buffers: AnyIterator<Any>? = nil
  ) {
    self.fileRead = fileRead
    self.fileReadline = fileReadline
    self.persistentLoader = persistentLoader
    self.encoding = encoding
    self.buffers = buffers
  }
    
  /// Convenience initializer for FileHandle.
  convenience init(
    fileHandle: FileHandle,
    persistentLoader: UnpicklerPersistentLoader?,
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
      persistentLoader: persistentLoader,
      encoding: encoding,
      buffers: buffers
    )
  }
  
  /// Convenience initializer for Data.
  convenience init(
    inputData: Data,
    persistentLoader: UnpicklerPersistentLoader?,
    encoding: PickledCompatiblityEncoding = .ascii,
    buffers: AnyIterator<Any>? = nil
  ) {
    var position: Int = 0
  
    self.init(
      fileRead: { count in
        guard position + count <= inputData.count else {
          return Data()
        }
        let returnedData = Data(inputData[position..<(position + count)])
        position += count
        return returnedData
      },
      fileReadline: {
        var newPosition = position
        let returnedData = inputData.withUnsafeBytes { (buffer: UnsafeRawBufferPointer) in
          while newPosition < inputData.count && buffer[newPosition] != Constants.endOfLineMarker {
            newPosition += 1
          }
          newPosition += newPosition < inputData.count ? 1 : 0
          return Data(inputData[position..<newPosition])
        }
        position = newPosition
        return returnedData
      },
      persistentLoader: persistentLoader,
      encoding: encoding,
      buffers: buffers
    )
  }
  
  /// Adds extension to the registry so that it can be called to create objects during unpickling.
  /// - Parameters:
  ///   - code: Code for the object on cache.
  ///   - module: Module name.
  ///   - className: Class name.
  func addExtension(code: Int, module: String, className: String) {
    invertedRegistry[code] = (module, className)
  }
    
  /// Main load method. Reads a pickled object representation from the file.
  /// - Returns: The reconstituted object
  /// - Throws: Any error during deserialization
  func load() throws -> UnpicklerValue? {
    // This is one-and-done. Return the parsed value object if we have already parsed it
    guard !stopReading else {
      return returnValue
    }
    
    // Reset the state when exiting the function and make sure that
    // unpickler goes to read-only state
    defer {
      stack = []
      metastack = []
      proto = 0
      stopReading = true
    }
    
    // Initialize the unframer
    unframer = Unframer(
        readFromResource: fileRead,
        readLineFromResource: fileReadline
    )
    
    #if DEBUG
    dispatchCounter = 0
    #endif
    
    // Main dispatch loop
    while !stopReading {
      #if DEBUG
      dispatchCounter += 1
      #endif
      let key = try read(1)
      if key.isEmpty {
        throw UnpicklerError.eof
      }
      
      let opcode = key[0]
      try dispatchOpcode(opcode)
    }
          
    return returnValue
  }
      
  /// Read n bytes from the unframer.
  /// Throws an error if can't read (exactly) n bytes.
  /// - Parameter n: Number of bytes to read.
  /// - Returns: Read data.
  private func read(_ n: Int) throws -> Data {
    return try unframer.read(n)
  }
    
  /// Reads a line from the unframer.
  /// Throws an error if not able to read a line ending to '\n'.
  /// - Returns: Data object ending to '\n'.
  private func readline() throws -> Data {
    return try unframer.readline()
  }
    
  /// Reads data into the given buffer.
  /// Throws an error if a frame is exhausted before reading the whole data to the buffer.
  /// - Parameter buffer: Buffer to read data into.
  /// - Returns: Amount of bytes read into the buffer.
  private func readinto(_ buffer: inout Data) throws -> Int {
    return try unframer.readInto(&buffer)
  }
    
  /// Append a value to the stack for later use.
  /// - Parameter value: Value to push to stack.
  private func append(_ value: UnpicklerValue) {
      stack.append(value)
  }
    
  /// Pop and return items from the stack after the last MARK.
  /// - Returns: List of items from metastack.
  private func popMark() -> [UnpicklerValue] {
      let items = stack
      stack = metastack.popLast() ?? []
      return items
  }
    
  /// Finds the correct class and to instantiate based on Python module and Python class.
  /// - Parameters:
  ///   - module: Python module where the class is located.
  ///   - name: Python class name.
  /// - Returns: Class to return.
  func findClass(module: String?, name: String) throws -> UnpicklerValue {
    guard let instantiatedClass = InstanceFactory.shared.createInstance(module: module, className: name) else {
      debugPrint("Could not create a new instance of class from module \(module ?? "") with class name \(name)")
      throw UnpicklerError.classCouldNotBeInstantiated
    }
    
    return instantiatedClass
  }
  
  /// Dispatch an opcode to its handler. Very core of the VM to perform the ops to restore the object graph.
  /// - Parameter opcode: Opcode to execute.
  private func dispatchOpcode(_ opcode: UInt8) throws {
    switch opcode {
      /// Basic types
      case PickleOpcode.proto: try loadProto()
      case PickleOpcode.frame: try loadFrame()
      case PickleOpcode.persId: try loadPersid()
      case PickleOpcode.binPersId: try loadBinpersid()
      case PickleOpcode.none: try loadNone()
      case PickleOpcode.newFalse: try loadFalse()
      case PickleOpcode.newTrue: try loadTrue()
        
      /// Integers
      case PickleOpcode.int: try loadInt()
      case PickleOpcode.binInt: try loadBinint()
      case PickleOpcode.binInt1: try loadBinint1()
      case PickleOpcode.binInt2: try loadBinint2()
      case PickleOpcode.long: try loadLong()
      case PickleOpcode.long1: try loadLong1()
      case PickleOpcode.long4: try loadLong4()
        
      /// Floats
      case PickleOpcode.float: try loadFloat()
      case PickleOpcode.binFloat: try loadBinfloat()
        
      /// Strings
      case PickleOpcode.string: try loadString()
      case PickleOpcode.binString: try loadBinstring()
      case PickleOpcode.shortBinString: try loadShortBinstring()
        
      /// Bytes
      case PickleOpcode.binBytes: try loadBinbytes()
      case PickleOpcode.shortBinBytes: try loadShortBinbytes()
      case PickleOpcode.binBytes8: try loadBinbytes8()
        
      /// Unicode string
      case PickleOpcode.unicode: try loadUnicode()
      case PickleOpcode.binUnicode: try loadBinunicode()
      case PickleOpcode.shortBinUnicode: try loadShortBinunicode()
      case PickleOpcode.binUnicode8: try loadBinunicode8()
        
      /// Tuples
      case PickleOpcode.emptyTuple: try loadEmptyTuple()
      case PickleOpcode.tuple1: try loadTuple1()
      case PickleOpcode.tuple2: try loadTuple2()
      case PickleOpcode.tuple3: try loadTuple3()
      case PickleOpcode.tuple: try loadTuple()
        
      /// Lists
      case PickleOpcode.emptyList: try loadEmptyList()
      case PickleOpcode.list: try loadList()
      
      /// Dictionaries
      case PickleOpcode.emptyDict: try loadEmptyDict()
      case PickleOpcode.dict: try loadDict()
      
      /// Sets
      case PickleOpcode.emptySet: try loadEmptySet()
      case PickleOpcode.frozenSet: try loadFrozenset()
      
      /// Memo operations
      case PickleOpcode.get: try loadGet()
      case PickleOpcode.binGet: try loadBinget()
      case PickleOpcode.longBinGet: try loadLongBinget()
      case PickleOpcode.put: try loadPut()
      case PickleOpcode.binPut: try loadBinput()
      case PickleOpcode.longBinPut: try loadLongBinput()
      case PickleOpcode.memoize: try loadMemoize()
      
      /// Container operations
      case PickleOpcode.append: try loadAppend()
      case PickleOpcode.appends: try loadAppends()
      case PickleOpcode.dictItem: try loadDictItem()
      case PickleOpcode.dictItems: try loadDictItems()
      case PickleOpcode.setItems: try loadSetItems()
      case PickleOpcode.build: try loadBuild()
      
      /// Stack operations
      case PickleOpcode.mark: try loadMark()
      case PickleOpcode.pop: try loadPop()
      case PickleOpcode.popMark: try loadPopMark()
      case PickleOpcode.dup: try loadDup()
      
      /// Object construction
      case PickleOpcode.reduce: try loadReduce()
      case PickleOpcode.newObj: try loadNewObject()
      case PickleOpcode.newObjEx: try loadNewObjectEx()
      case PickleOpcode.global: try loadGlobal()
      case PickleOpcode.stackGlobal: try loadStackGlobal()
      case PickleOpcode.inst: try loadInstance()
      case PickleOpcode.obj: try loadObject()
      
      /// Extensions
      case PickleOpcode.ext1: try loadExt1()
      case PickleOpcode.ext2: try loadExt2()
      case PickleOpcode.ext4: try loadExt4()
      
      /// Protocol 5
      case PickleOpcode.byteArray8: try loadBytearray8()
      case PickleOpcode.nextBuffer: try loadNextBuffer()
      case PickleOpcode.readonlyBuffer: try loadReadonlyBuffer()
      
      /// Control to stop reading the stream
      case PickleOpcode.stop: try loadStop()
        
      default:
        throw UnpicklerError.error("Unknown opcode: \(opcode)")
    }
  }

  // MARK: - Dispatch Methods
    
  /// Handles the stream start to check the version of the data store.
  private func loadProto() throws {
    let protoData = try read(1)
    let proto = Int(protoData[0])
    if proto < 0 || proto > Constants.highestSupportedProtocolVersion {
      throw UnpicklerError.unsupportedProtocol(proto)
    }
    self.proto = proto
  }
    
  /// Sets up frame.
  private func loadFrame() throws {
    let sizeData = try read(8)
    let frameSize = sizeData.withUnsafeBytes { $0.load(as: UInt64.self) }
    try unframer.loadFrame(frameSize: Int(frameSize))
  }
    
  /// Loads persistent data such as tensor data.
  private func loadPersid() throws {
    let line = try readline()
    guard let pidString = String(data: line.dropLast(), encoding: .ascii) else {
      throw UnpicklerError.error("Persistent IDs in protocol version 0 must be ASCII strings")
    }
    
    if let persistentLoader {
      let value = try persistentLoader.load([.string(pidString)])
      append(value)
    } else {
      logPrint("Persistent loader not defined or available so adding a null object to stack instead")
      append(.none)
    }
  }
    
  /// Loads persistent data such as tensor data.
  private func loadBinpersid() throws {
    if let pid = stack.removeLast().toAny() as? [UnpicklerValue] {
      if let persistentLoader {
        let value = try persistentLoader.load(pid)
        append(value)
      } else {
        logPrint("Persistent loader not defined or available so adding a null object to stack instead")
        append(.none)
      }
    }
  }
    
  /// Adds nil value to stack.
  private func loadNone() throws {
    append(.none)
  }
    
  /// Adds boolean false value to stack.
  private func loadFalse() throws {
    append(.bool(false))
  }
  
  /// Adds boolean true value to stack.
  private func loadTrue() throws {
    append(.bool(true))
  }
    
  /// Loads an int to stack.
  private func loadInt() throws {
    let data = try readline()
    let line = data.dropLast()
      
    // Check for special boolean values
    if line.dropFirst().elementsEqual([0x30, 0x30]) {
      append(.bool(false))
    } else if line.dropFirst().elementsEqual([0x30, 0x31]) {
      append(.bool(true))
    } else {
      guard let str = String(data: line, encoding: .ascii),
            let val = Int(str, radix: 10) else {
        throw UnpicklerError.error("Invalid integer format")
      }
      append(.int(val))
    }
  }
  
  /// Loads an int to stack.
  private func loadBinint() throws {
    let data = try read(4)
    let value = data.withUnsafeBytes { $0.load(as: Int32.self) }
    append(.int(Int(value)))
  }
    
  /// Loads an int to stack.
  private func loadBinint1() throws {
    let data = try read(1)
    append(.int(Int(data[0])))
  }
  
  /// Loads an int to stack.
  private func loadBinint2() throws {
    let data = try read(2)
    let value = data.withUnsafeBytes { $0.load(as: UInt16.self) }
    append(.int(Int(value)))
  }
  
  /// Loads an int to stack.
  private func loadLong() throws {
    let data = try readline()
    var line = data.dropLast()
      
    // Remove trailing 'L' if present
    if line.last == UInt8(ascii: "L") {
      line = line.dropLast()
    }
      
    guard let str = String(data: line, encoding: .ascii),
          let val = Int(str, radix: 10) else {
      throw UnpicklerError.error("Invalid long format")
    }
    append(.int(val))
  }
  
  /// Loads an int to stack.
  private func loadLong1() throws {
    let lenData = try read(1)
    let n = Int(lenData[0])
    let data = try read(n)
    let value = decodeLong(data)
    append(.int(value))
  }
  
  /// Loads an int to stack.
  private func loadLong4() throws {
    let lenData = try read(4)
    let n = lenData.withUnsafeBytes { $0.load(as: Int32.self) }
    
    if n < 0 {
      throw UnpicklerError.negativeByteCount
    }
    
    let data = try read(Int(n))
    let value = decodeLong(data)
    append(.int(value))
  }
  
  /// Loads a double to stack.
  private func loadFloat() throws {
    let data = try readline()
    let line = data.dropLast()
    
    guard let str = String(data: line, encoding: .ascii),
          let val = Double(str) else {
      throw UnpicklerError.error("Invalid float format")
    }
    append(.float(val))
  }
    
  /// Loads a double to stack.
  private func loadBinfloat() throws {
    let data = try read(8)
    let value = data.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) -> Double in
        let bytes = ptr.load(as: UInt64.self)
        let bigEndianBytes = UInt64(bigEndian: bytes)
        return Double(bitPattern: bigEndianBytes)
    }
    append(.float(value))
  }
    
  /// Decodes a string  from Python 2.
  private func decodeString(_ value: Data) throws -> String {
    if encoding == .bytes {
      // Return as string representation of bytes
      return value.map { String(format: "%02x", $0) }.joined()
    } else {
      let enc = encoding == .ascii ? String.Encoding.ascii : .utf8
        guard let str = String(data: value, encoding: enc) else {
          throw UnpicklerError.error("Failed to decode string")
        }
        return str
    }
  }
  
  /// Loads a string to stack.
  private func loadString() throws {
    var data = try readline()
    data = data.dropLast()  // Remove newline
    
    // Strip outermost quotes
    if data.count >= 2 && data.first == data.last && data.first == UInt8(ascii: "'") {
      data = data.dropFirst().dropLast()
    } else {
      throw UnpicklerError.error("STRING opcode argument must be quoted")
    }
    
    let str = try decodeString(data)
    append(.string(str))
  }
    
  /// Loads a string to stack.
  private func loadBinstring() throws {
    let lenData = try read(4)
    let len = lenData.withUnsafeBytes { $0.load(as: Int32.self) }
    
    if len < 0 {
      throw UnpicklerError.negativeByteCount
    }
    
    let data = try read(Int(len))
    let str = try decodeString(data)
    append(.string(str))
  }
  
  /// Loads a string to stack.
  private func loadShortBinstring() throws {
    let lenData = try read(1)
    let len = Int(lenData[0])
    let data = try read(len)
    let str = try decodeString(data)
    append(.string(str))
  }
  
  /// Loads binary blob to stack.
  private func loadBinbytes() throws {
    let lenData = try read(4)
    let len = lenData.withUnsafeBytes { $0.load(as: UInt32.self) }
    
    if len > Int.max {
      throw UnpicklerError.exceedsMaxSize
    }
    
    let data = try read(Int(len))
    append(.bytes(data))
  }
  
  /// Loads binary blob to stack.
  private func loadShortBinbytes() throws {
    let lenData = try read(1)
    let len = Int(lenData[0])
    let data = try read(len)
    append(.bytes(data))
  }
  
  /// Loads binary blob to stack.
  private func loadBinbytes8() throws {
    let lenData = try read(8)
    let len = lenData.withUnsafeBytes { $0.load(as: UInt64.self) }
    
    if len > Int.max {
      throw UnpicklerError.exceedsMaxSize
    }
    
    let data = try read(Int(len))
    append(.bytes(data))
  }
  
  /// Decodes raw-unicode-escape Pytthon string.
  /// - Parameter data: String data.
  /// - Returns: Decoded string or nil if decoding failed.
  private func decodeRawUnicodeEscape(_ data: Data) -> String? {
    // Latin-1 decode (0x00–0xFF -> U+0000–U+00FF)
    guard let s = String(data: data, encoding: .isoLatin1) else { return nil }

    // Turn \uXXXX and \UXXXXXXXX into real characters
    let ms = NSMutableString(string: s)
    let ok = CFStringTransform(ms, nil, "Any-Hex/Java" as CFString, true) // reverse = true
    return ok ? (ms as String) : s
  }
  
  /// Loads (unicode) string to stack.
  private func loadUnicode() throws {
    let data = try readline()
    let line = data.dropLast()
          
    guard let str = decodeRawUnicodeEscape(line) else {
      throw UnpicklerError.error("Failed to decode unicode")
    }
    append(.string(str))
  }
  
  /// Loads (unicode) string to stack.
  private func loadBinunicode() throws {
    let lenData = try read(4)
    let len = lenData.withUnsafeBytes { $0.load(as: UInt32.self) }
    
    if len > Int.max {
      throw UnpicklerError.exceedsMaxSize
    }
    
    let data = try read(Int(len))
    // This will not decode properly if there are surrogate UTF-16 code points present
    let str = String(decoding: data, as: UTF8.self)
    append(.string(str))
  }
  
  /// Loads (unicode) string to stack.
  private func loadShortBinunicode() throws {
    let lenData = try read(1)
    let len = Int(lenData[0])
    let data = try read(len)
    // This will not decode properly if there are surrogate UTF-16 code points present
    let str = String(decoding: data, as: UTF8.self)
    append(.string(str))
  }
    
  /// Loads (unicode) string to stack.
  private func loadBinunicode8() throws {
    let lenData = try read(8)
    let len = lenData.withUnsafeBytes { $0.load(as: UInt64.self) }
    
    if len > Int.max {
      throw UnpicklerError.exceedsMaxSize
    }
    
    let data = try read(Int(len))
    // This will not decode properly if there are surrogate UTF-16 code points present
    let str = String(decoding: data, as: UTF8.self)
    append(.string(str))
  }
  
  /// Loads empty tuple (list) to stack.
  private func loadEmptyTuple() throws {
    append(.tuple([]))
  }
  
  /// Loads tuple (list) to stack, adds last item from stack to it.
  private func loadTuple1() throws {
    let item = stack.removeLast()
    append(.tuple([item]))
  }
    
  /// Loads tuple (list) to stack, adds two last items from stack to it.
  private func loadTuple2() throws {
    let item2 = stack.removeLast()
    let item1 = stack.removeLast()
    append(.tuple([item1, item2]))
  }
  
  /// Loads tuple (list) to stack, adds three last items from stack to it.
  private func loadTuple3() throws {
    let item3 = stack.removeLast()
    let item2 = stack.removeLast()
    let item1 = stack.removeLast()
    append(.tuple([item1, item2, item3]))
  }
    
  /// Loads tuple (list) to stack, pops items from metastack.
  private func loadTuple() throws {
    let items = popMark()
    append(.tuple(items))
  }
   
  /// Loads empty list to stack.
  private func loadEmptyList() throws {
    append(.list([]))
  }

  /// Loads list to stack, pops items from metastack.
  private func loadList() throws {
    let items = popMark()
    append(.list(items))
  }
  
  /// Loads empty dictionary to stack.
  private func loadEmptyDict() throws {
    append(.dict([:]))
  }
  
  /// Loads dictionary to stack. Gets items from metastack and then adds them as key, value pairs to dictionary.
  private func loadDict() throws {
    let items = popMark()
    var dict: [AnyHashable: Any] = [:]
    
    var i = 0
    while i < items.count - 1 {
        let key = items[i].toAny() as! AnyHashable
        let value = items[i + 1]
        dict[key] = value.toAny()
        i += 2
    }
    
    append(.dict(dict))
  }
    
  /// Loads empty set to stack.
  private func loadEmptySet() throws {
    append(.set(Set()))
  }
    
  /// Loads set from metastack to stack.
  private func loadFrozenset() throws {
    let items = popMark()
    let hashableItems = items.map { $0.toAny() as! AnyHashable }
    append(.set(Set(hashableItems)))
  }
  
  /// Loads value from memo dictionary and pushes it to stack.
  private func loadGet() throws {
      let data = try readline()
      let line = data.dropLast()
      
      guard let str = String(data: line, encoding: .ascii),
            let i = Int(str) else {
          throw UnpicklerError.error("Invalid GET index")
      }
      
      guard let value = memo[i] else {
          throw UnpicklerError.memoNotFound(i)
      }
      
      append(value)
  }
  
  /// Loads value from memo dictionary and pushes it to stack.
  private func loadBinget() throws {
      let data = try read(1)
      let i = Int(data[0])
      
      guard let value = memo[i] else {
          throw UnpicklerError.memoNotFound(i)
      }
      
      append(value)
  }
  
  /// Loads value from memo dictionary and pushes it to stack.
  private func loadLongBinget() throws {
      let data = try read(4)
      let i = data.withUnsafeBytes { $0.load(as: UInt32.self) }
      
      guard let value = memo[Int(i)] else {
          throw UnpicklerError.memoNotFound(Int(i))
      }
      
      append(value)
  }
  
  /// Stores value from stack to memo.
  private func loadPut() throws {
    let data = try readline()
    let line = data.dropLast()
    
    guard let str = String(data: line, encoding: .ascii),
          let i = Int(str) else {
      throw UnpicklerError.error("Invalid PUT index")
    }
      
    if i < 0 {
      throw UnpicklerError.negativeArgument
    }
    
    guard let lastItem = stack.last else {
      throw UnpicklerError.error("Nothing in stack to put to memo location \(i)")
    }
      
    memo[i] = lastItem
  }
    
  /// Stores value from stack to memo.
  private func loadBinput() throws {
    let data = try read(1)
    let i = Int(data[0])
    
    if i < 0 {
        throw UnpicklerError.negativeArgument
    }
    
    guard let lastItem = stack.last else {
      throw UnpicklerError.error("Nothing in stack to put to memo location \(i)")
    }
      
    memo[i] = lastItem
  }
  
  /// Stores value from stack to memo.
  private func loadLongBinput() throws {
    let data = try read(4)
    let i = data.withUnsafeBytes { $0.load(as: UInt32.self) }
    
    if i > Int.max {
      throw UnpicklerError.negativeArgument
    }
    
    guard let lastItem = stack.last else {
      throw UnpicklerError.error("Nothing in stack to put to memo location \(i)")
    }
      
    memo[Int(i)] = lastItem
  }
  
  /// Store value from stack to memo.
  private func loadMemoize() throws {
    let idx = memo.count
    
    guard let lastItem = stack.last else {
      throw UnpicklerError.error("Nothing in stack to put to memo location \(idx)")
    }
    memo[idx] = lastItem
  }
    
  /// Pop value from stack and add it to the list in the stack.
  private func loadAppend() throws {
    let value = stack.removeLast()
    if case .list(var list) = stack.removeLast() {
      list.append(value)
      append(.list(list))
    } else {
      throw UnpicklerError.error("Append requires a list")
    }
  }
  
  /// Pops list from metastack and adds it to the list in the stack.
  private func loadAppends() throws {
    let items = popMark()
    if case .list(var list) = stack.removeLast() {
      list.append(contentsOf: items)
      append(.list(list))
    } else {
      throw UnpicklerError.error("Appends requires a list")
    }
  }
  
  /// Pops list from metastack and adds it to the list in the stack.
  private func loadDictItem() throws {
    let value = stack.removeLast()
    let key = stack.removeLast()
    
    if case .dict(var dict) = stack.removeLast() {
      dict[key.toAny() as! AnyHashable] = value
      append(.dict(dict))
    } else {
      throw UnpicklerError.error("loadDictItem() requires a dict")
    }
  }
  
  /// Pops list from metastack and adds its items to the dictionary in the stack.
  private func loadDictItems() throws {
    let items = popMark()
    
    let dictItem = stack.removeLast()
    
    if var dict = dictItem.dict {
      var i = 0
      while i < items.count - 1 {
        let key = items[i].toAny() as! AnyHashable
        let value = items[i + 1]
        dict[key] = value.toAny()
        i += 2
      }
      append(.dict(dict))
    } else {
      throw UnpicklerError.error("loadDictItems() requires a dict")
    }
  }
  
  /// Pops list from metastack and adds its items to set in the stack.
  private func loadSetItems() throws {
    let items = popMark()
    
    if case .set(var set) = stack.removeLast() {
      items.forEach { set.insert($0.toAny() as! AnyHashable) }
      append(.set(set))
    } else {
      throw UnpicklerError.error("loadSetItems() requires a set")
    }
  }
    
  /// Applies saved state to an object.
  private func loadBuild() throws {
    let state = stack.removeLast()
    let object = stack.removeLast()
            
    // logPrint("Should build function \(object)")
    append(InstanceFactory.shared.initializeInstance(object: object, arguments: state))
  }
  
  /// Moves all items from stack to metastack.
  private func loadMark() throws {
    metastack.append(stack)
    stack = []
  }
  
  /// Pop either last item from stack or if stack is empty, pop items from metastack.
  private func loadPop() throws {
    if !stack.isEmpty {
      stack.removeLast()
    } else {
      _ = popMark()
    }
  }
  
  /// Pops items from metastack.
  private func loadPopMark() throws {
    _ = popMark()
  }
   
  /// Duplicates last item on stack. Does not do deep copy of the item though for sets, dictionaries or lists.
  private func loadDup() throws {
    guard let lastItem = stack.last else {
      throw UnpicklerError.error("Dup requires at least one item on the stack")
    }
    append(lastItem)
  }
  
  /// Performs function call with given arguments from the stack and pushes output value to stack.
  private func loadReduce() throws {
    let args = stack.removeLast()
    let object = stack.removeLast()
    
    logPrint("Should call function/constructor \(object) with args \(args)")
    append(InstanceFactory.shared.initializeInstance(object: object, arguments: args))
  }
    
  /// Creates instance of new object and pushes it to the stack.
  private func loadNewObject() throws {
    let args = stack.removeLast()
    let object = stack.removeLast()
        
    logPrint("Should call function/constructor \(object) with args \(args)")
    append(InstanceFactory.shared.initializeInstance(object: object, arguments: args))
  }
    
  /// Creates instance of new object and pushes it to the stack.
  private func loadNewObjectEx() throws {
    let kwArgs = stack.removeLast()
    let args = stack.removeLast()
    let className = stack.removeLast()
    
    debugPrint("loadNewObjectEX() is not right now supported! Should create class \(className) with args \(args) and keywordArgs \(kwArgs)")
      
    // For now, just push a placeholder
    append(args)
  }
  
  /// Creates instnace of new object and pushes it to the stack.
  private func loadGlobal() throws {
    let moduleLine = try readline()
    let nameLine = try readline()
    
    guard let module = String(data: moduleLine.dropLast(), encoding: .utf8),
          let name = String(data: nameLine.dropLast(), encoding: .utf8) else {
      throw UnpicklerError.error("Failed to decode global")
    }
    
    append(try findClass(module: module, name: name))
  }
    
  /// Creates instnace of new object and pushes it to the stack.
  private func loadStackGlobal() throws {
    guard case .string(let name) = stack.removeLast(),
          case .string(let module) = stack.removeLast() else {
      throw UnpicklerError.error("STACK_GLOBAL requires str")
    }
    
    let klass = try findClass(module: module, name: name)
    append(klass)
  }
  
  /// Loads object from cache based on index from stack.
  private func loadExt1() throws {
    let data = try read(1)
    let code = Int(data[0])
    try getExtension(code: code)
  }
  
  /// Loads object from cache based on index from stack.
  private func loadExt2() throws {
    let data = try read(2)
    let code = data.withUnsafeBytes { $0.load(as: UInt16.self) }
    try getExtension(code: Int(code))
  }
  
  /// Loads object from cache based on index from stack.
  private func loadExt4() throws {
    let data = try read(4)
    let code = data.withUnsafeBytes { $0.load(as: Int32.self) }
    try getExtension(code: Int(code))
  }
    
  /// Loads object from cache based on index from stack.
  /// - Parameter code: Cache lookup key.
  private func getExtension(code: Int) throws {
    if code <= 0 {
      throw UnpicklerError.error("EXT specifies code <= 0")
    }
    
    if let (module, className) = invertedRegistry[code] {
      let object = try findClass(module: module, name: className)
      append(.any(object))
    } else {
      throw UnpicklerError.unregisteredExtension(code)
    }
  }
  
  /// Creates an object and initializes with values from metastack.
  private func loadInstance() throws {
    let moduleLine = try readline()
    let nameLine = try readline()
    
    guard let module = String(data: moduleLine.dropLast(), encoding: .ascii),
          let name = String(data: nameLine.dropLast(), encoding: .ascii) else {
        throw UnpicklerError.error("Failed to decode INST")
    }
    
    let object = try findClass(module: module, name: name)
    let values = popMark()
    append(InstanceFactory.shared.initializeInstance(object: object, arguments: .list(values)))
  }
    
  /// Creates an object and initializes it from metastack values.
  private func loadObject() throws {
    var args = popMark()
    let className = args.removeFirst().string
    
    if let className {
      let object = try findClass(module: nil, name: className)
      append(InstanceFactory.shared.initializeInstance(object: object, arguments: .list(args)))
    }
  }
    
  /// Loads bytearray into stack.
  private func loadBytearray8() throws {
    let lenData = try read(8)
    let len = lenData.withUnsafeBytes { $0.load(as: UInt64.self) }
    
    if len > Int.max {
        throw UnpicklerError.exceedsMaxSize
    }
    
    var buffer = Data(count: Int(len))
    _ = try readinto(&buffer)
    append(.bytes(buffer))
  }
  
  /// Loads next value from a given buffer to stack.
  private func loadNextBuffer() throws {
    guard let buffers = buffers else {
      throw UnpicklerError.error("pickle stream refers to out-of-band data but no buffers argument was given")
    }
    
    guard let buf = buffers.next() else {
      throw UnpicklerError.error("not enough out-of-band buffers")
    }
    
    append(.any(buf))
  }
    
  /// No-op.
  private func loadReadonlyBuffer() throws {
    // In Swift, we don't have the same readonly buffer concept
    // Just leave the buffer as-is on the stack
  }
    
  /// Removes last item for stack to be the return value and stops the reading loop.
  private func loadStop() throws {
    returnValue = stack.removeLast()
    stopReading = true
  }
    
  // MARK: - Utility Functions
    
  /// Decode a long from two's complement little-endian bytes.
  /// - Parameter data: Data to decode.
  /// - Returns: Integer value.
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

