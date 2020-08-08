import Foundation
import Dispatch
import ArgumentParser
import GSDumpReader

struct GSDumpCLI: ParsableCommand {
	static var configuration = CommandConfiguration(
		commandName: CommandLine.arguments[0],
		abstract: "A CLI for managing PCSX2's gsdumps"
	)

	@Argument(help: "The GSdx binary", completion: .file(extensions: ["dll", "dylib", "so"]))
	var gsdx: String

	@Argument(help: "The dump to play", completion: .file(extensions: [".gs"]))
	var dump: String

	@Flag(inversion: .prefixedNo, help: "Show the GSdx config window before starting")
	var configWindow: Bool = true

	@Option(name: [.short, .customLong("config-dir")], help: "The directory containing the GSdx.ini to use", completion: .directory)
	var configDir: String?

	func run() throws {
		let gsdx = try GSdx(dll: self.gsdx)
		let dump = try GSDump(contentsOfFile: self.dump)
		var error: Error? = nil
		var done = false
		configDir.map { gsdx.setSettingsDir($0) }
		if configWindow {
			gsdx.configure()
			waitForConfigure()
		}
		DispatchQueue.global().async {
			defer { DispatchQueue.main.sync { done = true } }
			do {
				let player = try GSDumpPlayer(gsdx: gsdx, dump: dump)
				while true {
					for data in dump.data {
						player.execute(data)
					}
				}
			} catch let e {
				DispatchQueue.main.sync { error = e }
			}
		}
		while !done {
			RunLoop.main.run(mode: .default, before: .distantFuture)
		}
		if let error = error {
			throw error
		}
	}
}
