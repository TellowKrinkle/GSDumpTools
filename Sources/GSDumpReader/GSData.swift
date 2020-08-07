public enum GSData {
	case transfer(path: TransferPath, data: [UInt8])
	case vsync(data: UInt8)
	case readFIFO2(size: Int32)
	case registers(data: [UInt8])

	public enum TransferPath: UInt8 {
		case path1Old = 0
		case path2 = 1
		case path3 = 2
		case path1New = 3
	}

	public enum Tag: UInt8 {
		case transfer = 0
		case vsync = 1
		case readFIFO2 = 2
		case registers = 3
	}
}

extension GSData: CustomStringConvertible {
	public var description: String {
		switch self {
		case .transfer(let path, let data):
			return "Transfer(\(path), \(data.count) bytes)"
		case .vsync(let data):
			return "VSync \(data)"
		case .readFIFO2(let size):
			return "ReadFIFO2(\(size) bytes)"
		case .registers(_):
			return "Registers"
		}
	}
}
