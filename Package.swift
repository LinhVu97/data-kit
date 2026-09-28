// swift-tools-version: 5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "FidraData",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v15),
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "FidraData",
            targets: ["FidraData"]),
    ],
    dependencies: [
        .package(url: "https://gitlab.volio.vn/fidra/libs/data-storage-kit.git", .upToNextMajor(from: "1.0.4")),
        .package(url: "https://github.com/realm/realm-swift.git", .upToNextMajor(from: "20.0.5"))
    ],
    targets: [
        .target(
            name: "FidraData",
            dependencies: [
                .product(name: "DataStorageKit", package: "data-storage-kit"),
                .product(name: "RealmSwift", package: "realm-swift")
            ]
        )
    ]
)
