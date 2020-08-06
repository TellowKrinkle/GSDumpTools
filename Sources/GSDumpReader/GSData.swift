public enum GSData {
	case transfer(path: TransferPath, data: [UInt8])
	case vsync(data: UInt8)
	case readFIFO2(data: [UInt8])
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
