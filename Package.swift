// swift-tools-version: 5.9
import PackageDescription

let package = Package(
	name: "Clonk",
	platforms: [
		.macOS(.v14)
	],
	products: [
		.executable(
			name: "Clonk",
			targets: ["Clonk"]
		)
	],
	targets: [
		.executableTarget(
			name: "Clonk",
			path: "Clonk",
			exclude: ["Info.plist"]
		),
		.executableTarget(
			name: "ClonkTests",
			path: "Tests/ClonkTests"
		)
	]
)
