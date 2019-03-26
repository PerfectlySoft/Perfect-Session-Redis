// swift-tools-version:4.2
// Generated automatically by Perfect Assistant Application
// Date: 2017-10-03 21:25:08 +0000
import PackageDescription
let package = Package(
	name: "PerfectSessionRedis",
	products: [
		.library(name: "PerfectSessionRedis", targets: ["PerfectSessionRedis"])
	],
	dependencies: [
		.package(url: "https://github.com/PerfectlySoft/Perfect-Session.git", from: "3.0.0"),
		.package(url: "https://github.com/PerfectlySoft/Perfect-Redis.git", from: "3.0.0"),
	],
	targets: [
		.target(name: "PerfectSessionRedis", dependencies: ["PerfectSession", "PerfectRedis"])
	]
)
