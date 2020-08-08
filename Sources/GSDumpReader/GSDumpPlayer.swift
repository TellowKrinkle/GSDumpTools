import CGSdxDefs

fileprivate var dataSink: UnsafeMutableRawBufferPointer = .allocate(byteCount: 0, alignment: 0)

public class GSDumpPlayer {
	let gsdx: GSdx
	public var registers: UnsafeMutableRawBufferPointer

	public init(gsdx: GSdx, dump: GSDump) throws {
		var success = false

		self.gsdx = gsdx
		self.registers = .allocate(byteCount: 8192, alignment: 32)
		defer { if !success { registers.deallocate() } }

		updateRegisters(dump.registers)
		gsdx.`init`()
		gsdx.setBaseMem(registers.baseAddress!)
		var wnd: OpaquePointer? = nil
		try gsdx.open(wnd: &wnd, title: "")
		defer { if !success { gsdx.close() } }
		gsdx.setGameCRC(dump.crc, 0)

		try dump.stateData.withUnsafeBytes { ptr in
			// Yay for C apis thinking "save" and "load" can share a type signature
			let mutPtr = UnsafeMutableRawPointer(mutating: ptr.baseAddress!)
			var data = GSFreezeData(size: Int32(ptr.count), data: mutPtr)
			try gsdx.freeze(mode: .load, data: &data)
			gsdx.vsync(1)

			gsdx.reset()
			updateRegisters(dump.registers)
			gsdx.setBaseMem(registers.baseAddress!)
			try gsdx.freeze(mode: .load, data: &data)
		}

		success = true
	}

	deinit {
		gsdx.close()
		registers.deallocate()
	}

	public func updateRegisters(_ newRegs: [UInt8]) {
		precondition(newRegs.count == 8192)
		newRegs.withUnsafeBytes { src in
			registers.copyMemory(from: src)
		}
	}

	public func readFIFO2(size: Int32) {
		let size = Int(size)
		if dataSink.count < size {
			dataSink.deallocate()
			dataSink = .allocate(byteCount: size, alignment: 32)
		}
		gsdx.readFIFO2(into: .init(rebasing: dataSink[..<size]))
	}

	public func transfer(_ data: [UInt8], path: GSData.TransferPath) {
		data.withUnsafeBytes { ptr in
			gsdx.gifTransfer(ptr, path: path)
		}
	}

	public func vsync() {
		let item = registers.withUnsafeBytes { ptr in
			Int32(littleEndian: ptr.load(fromByteOffset: 4096, as: Int32.self))
		}
		gsdx.vsync(item & 0x2000 > 0 ? 1 : 0)
	}

	public func execute(_ data: GSData) {
		switch data {
		case .registers(let regs):
			updateRegisters(regs)
		case .transfer(let path, let data):
			transfer(data, path: path)
		case .readFIFO2(let size):
			readFIFO2(size: size)
		case .vsync(_):
			vsync()
		}
	}
}
