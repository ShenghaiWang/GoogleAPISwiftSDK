// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "GoogleAPISwiftSDK",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(
            name: "GoogleSheetsSDK",
            targets: ["GoogleSheetsSDK"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/ShenghaiWang/GoogleAPITokenManager.git", from: "0.1.0"),
    ],
    targets: [
        .target(
            name: "GoogleSheetsSDK",
            dependencies: [
                "GoogleAPITokenManager",
            ],
            path: "Sources/GoogleSheetsSDK"
        ),
        .executableTarget(name: "Client",
                          dependencies: [
                              "GoogleSheetsSDK",
                          ]),
    ]
)
