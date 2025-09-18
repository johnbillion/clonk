// swift-tools-version: 5.9
import PackageDescription

let package = Package(
	name: "Clonk",
	defaultLocalization: "en",
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
			exclude: [
				"Info.plist",
				"AppIcon.icns",
				"AppIcon.iconset"
			],
			resources: [
				.process("Localizable.strings"),
				.process("en.lproj")
			]
		),
		.executableTarget(
			name: "ClonkTests",
			path: "Tests/ClonkTests"
		)
	]
)
