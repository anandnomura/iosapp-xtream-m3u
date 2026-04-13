// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "IPTVAppCore",
    platforms: [
        .iOS(.v17),
        .tvOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "IPTVDomain",
            targets: ["IPTVDomain"]
        ),
        .library(
            name: "IPTVData",
            targets: ["IPTVData"]
        )
    ],
    targets: [
        .target(
            name: "IPTVDomain"
        ),
        .target(
            name: "IPTVData",
            dependencies: ["IPTVDomain"]
        ),
        .testTarget(
            name: "IPTVDomainTests",
            dependencies: ["IPTVDomain"]
        ),
        .testTarget(
            name: "IPTVDataTests",
            dependencies: ["IPTVData", "IPTVDomain"]
        )
    ]
)
