import BinaryReader

extension BinaryReader {
	mutating func forceReadI32SizedBytes() throws -> [UInt8] {
		let size = Int(try forceReadLE() as Int32)
		return try forceReadBytes(size)
	}
}

struct GSDump {
	public var crc: Int32
	public var stateData: [UInt8]
	public var registers: [UInt8] // 8192 bytes
	public var data: [GSData]
}

extension GSDump {
	public enum ReadError: Error {
		case unexpectedGSType(UInt8)
		case unexpectedGSTransferPath(UInt8)
		case xzIsNotYetSupported
	}

	public init<Reader: BinaryReader>(readingFrom reader: inout Reader) throws {
		crc = try reader.forceReadLE()
		stateData = try reader.forceReadI32SizedBytes()
		registers = try reader.forceReadBytes(8192)
		data = []
		while let next: UInt8 = try reader.read() {
			guard let type = GSData.Tag(rawValue: next) else {
				throw ReadError.unexpectedGSType(next)
			}
			switch type {
			case .transfer:
				let index: UInt8 = try reader.forceRead()
				guard let path = GSData.TransferPath(rawValue: index) else {
					throw ReadError.unexpectedGSTransferPath(index)
				}
				let bytes = try reader.forceReadI32SizedBytes()
				data.append(.transfer(path: path, data: bytes))
			case .vsync:
				data.append(.vsync(data: try reader.forceRead()))
			case .readFIFO2:
				data.append(.readFIFO2(data: try reader.forceReadI32SizedBytes()))
			case .registers:
				data.append(.registers(data: try reader.forceReadBytes(8192)))
			}
		}
	}

	public init(contentsOfFile path: String) throws {
		var fileReader = try FileReader(path: path)
		let start = try fileReader.readAtMostBytes(6)
		try fileReader.seek(to: 0)
		if start == [0xFD, 0x37, 0x7A, 0x58, 0x5A, 0x00] {
			// XZ header
			throw ReadError.xzIsNotYetSupported
		} else {
			var reader = try BufferedReader(fileReader, bufferSize: 65536)
			try self.init(readingFrom: &reader)
		}
	}
}
