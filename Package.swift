// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "Unrealm",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "UnrealmObjC",
            targets: ["UnrealmObjC"]),
        .library(
            name: "Unrealm",
            targets: [
                "Unrealm",
                "UnrealmObjC"
            ])
    ],
    dependencies: [
        .package(name: "Realm", url: "https://github.com/realm/realm-cocoa.git", from: "10.6.0"),
        .package(url: "https://github.com/wickwirew/Runtime.git", from: "2.1.0"),
        .package(name: "SnapshotTesting", url: "https://github.com/pointfreeco/swift-snapshot-testing.git", .upToNextMajor(from: "1.7.2")),
    ],
    targets: [
        .target(
            name: "UnrealmObjC",
            dependencies: [
                "Realm",
                .product(name: "RealmSwift", package: "Realm")
            ],
            path: "Unrealm/Classes/ObjC"),
        .target(
            name: "Unrealm",
            dependencies: [
                "UnrealmObjC",
                "Realm",
                .product(name: "RealmSwift", package: "Realm"),
                "Runtime"
            ],
            path: "Unrealm/Classes/Swift"),
        .testTarget(
            name: "UnrealmTests",
            dependencies: [
                "Unrealm",
                "SnapshotTesting",
                .product(name: "RealmSwift", package: "Realm")
            ],
            path: "Unrealm/Tests")
    ])
