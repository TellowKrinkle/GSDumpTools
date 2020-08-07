// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "GSDumpReader",
	products: [
		// Products define the executables and libraries produced by a package, and make them visible to other packages.
		.library(
			name: "GSDumpReader",
			targets: ["GSDumpReader"]
		),
	],
	dependencies: [
		// Dependencies declare other packages that this package depends on.
		// .package(url: /* package url */, from: "1.0.0"),
		.package(name: "BinaryReader", url: "https://github.com/tellowkrinkle/SwiftBinaryReader.git", from: "0.1.1"),
		.package(url: "https://github.com/apple/swift-argument-parser", .upToNextMinor(from: "0.2.0")),
	],
	targets: [
		// Targets are the basic building blocks of a package. A target can define a module or a test suite.
		// Targets can depend on other targets in this package, and on products in packages which this package depends on.
		.target(name: "CGSdxDefs"),
		.target(
			name: "GSDumpReader",
			dependencies: ["CGSdxDefs", "BinaryReader"]
		),
		.testTarget(
			name: "GSDumpReaderTests",
			dependencies: ["GSDumpReader"]
		),
		.target(
			name: "GSDumpCLI",
			dependencies: [
				"GSDumpReader",
				.product(name: "ArgumentParser", package: "swift-argument-parser")
			]
		),
	]
)
