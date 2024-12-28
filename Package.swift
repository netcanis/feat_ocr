// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "feat_ocr",
    platforms: [.iOS(.v16)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(name: "feat_ocr", targets: ["feat_ocr"]),
    ],
    dependencies: [
        // Define external dependencies here using GitHub URLs or package names.
    ],
    targets: [
        // Binary Target for Prebuilt C++ Library
        .binaryTarget(
            name: "HiOCR",
            path: "Frameworks/HiOCR.xcframework"
        ),
        // Objective-C Class
        .target(
            name: "HiOCRWrapper",
            dependencies: [
                "HiOCR"
            ],
            path: "Sources/HiOCRWrapper",
            publicHeadersPath: ".",
            cSettings: [
                .headerSearchPath("../../Headers"),
                .define("SWIFT_PACKAGE"),
                .unsafeFlags(["-std=c++20"])
            ],
            linkerSettings: [
                .linkedFramework("opencv2"),
            ]
        ),
        // Swift Module
        .target(
            name: "feat_ocr",
            dependencies: [
                "HiOCRWrapper"
            ],
            path: "Sources/feat_ocr",
            resources: [
                .process("Assets.xcassets")
            ]
        ),
        .testTarget(
            name: "feat_ocrTests",
            dependencies: ["feat_ocr"],
            path: "Tests"
        ),
    ]
)
