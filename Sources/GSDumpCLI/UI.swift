import Foundation

func waitForConfigure() {
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
