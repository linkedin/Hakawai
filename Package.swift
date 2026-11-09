// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "Hakawai",
    platforms: [.iOS("10.0")],
    products: [
        .library(name: "Hakawai", targets: ["Hakawai"]),
    ],
    targets: [
        .target(
            name: "Hakawai",
            path: "Hakawai",
            exclude: ["Hakawai-Prefix.pch"],
            sources: ["Core", "Mentions"],
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("Core"),
                .headerSearchPath("Core/AbstractionLayer"),
                .headerSearchPath("Core/Default"),
                .headerSearchPath("Core/TextKit"),
            ],
            linkerSettings: [.linkedFramework("UIKit")]
        ),
    ]
)
