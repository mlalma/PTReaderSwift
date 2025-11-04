import Foundation

/// Supported pickle opcodes.
struct PickleOpcode: Sendable {
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
  static let dictItem: UInt8 = 0x73
  /// Build tuple from topmost stack items
  static let tuple: UInt8 = 0x74
  /// Push empty tuple
  static let emptyTuple: UInt8 = 0x29
  /// Modify dict by adding topmost key+value pairs
  static let dictItems: UInt8 = 0x75
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
  static let setItems: UInt8 = 0x90
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


