import Foundation
import Dispatch
import ArgumentParser
import GSDumpReader

struct GSDumpCLI: ParsableCommand {
	static var configuration = CommandConfiguration(
		commandName: CommandLine.arguments[0],
		abstract: "A CLI for managing PCSX2's gsdumps",
		subcommands: [Configure.self, Replay.self]
	)
}

extension GSDumpCLI {
	struct Configure: ParsableCommand {
		@Argument(help: "The GSdx binary", completion: .file(extensions: ["dll", "dylib", "so"]))
		var gsdx: String

		func run() throws {
			let gsdx = try GSdx(dll: self.gsdx)
			gsdx.configure()
			#if os(macOS)
			for _ in 0..<10 {
				// Hack to wait until configure window closes
				// GTK blocks the event loop, which prevents us from running any code while the configure window is in the foreground
				// Since it blocks the event loop, running it 10 times will successfully block until its window closes
				// Note: Will probably break when GSdx switches to wx
				RunLoop.main.run(mode: .default, before: .distantFuture)
			}
			#endif
		}
	}
}


extension GSDumpCLI {
	struct Replay: ParsableCommand {
		@Argument(help: "The GSdx binary", completion: .file(extensions: ["dll", "dylib", "so"]))
		var gsdx: String

		@Argument(help: "The dump to play", completion: .file(extensions: [".gs"]))
		var dump: String

		func run() throws {
			let gsdx = try GSdx(dll: self.gsdx)
			let dump = try GSDump(contentsOfFile: self.dump)
			var error: Error? = nil
			var done = false
			gsdx.configure()
			DispatchQueue.global().async {
				defer { DispatchQueue.main.sync { done = true } }
				let player = GSDumpPlayer(gsdx: gsdx)
				do {
					try player.open(dump, renderer: .ogl_hw)
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
}
