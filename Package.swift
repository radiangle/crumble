// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Crumble",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "Crumble",
            path: "Sources/Crumble",
            exclude: ["Info.plist"],
            linkerSettings: [
                .unsafeFlags([
                    "-Xlinker", "-sectcreate",
                    "-Xlinker", "__TEXT",
                    "-Xlinker", "__info_plist",
                    "-Xlinker", "Sources/Crumble/Info.plist"
                ])
            ]
        )
    ]
)
