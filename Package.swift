// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "JournifyFirebase",
    platforms: [
        .macOS("10.15"),
        .iOS("13.0"),
        .tvOS("11.0"),
        .watchOS("7.1")
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "JournifyFirebase",
            targets: ["JournifyFirebase"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(
            name: "Journify",
            url: "https://github.com/journifyio/journify-ios-sdk.git",
            from: "0.0.6"
        ),
		.package(
			name: "Firebase",
			url: "https://github.com/firebase/firebase-ios-sdk",
			from: "10.23.1"
		)
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "JournifyFirebase",
            dependencies: ["Journify",
                            .product(
                                name: "FirebaseAnalytics",
                                package: "Firebase")
                          ]
        ),
        
        // TESTS ARE HANDLED VIA THE EXAMPLE APP.
    ]
)

