//@testable import Build
//@testable import PackageGraph
@testable import PackageModel
import Basics
//import PackageLoading
import SPMBuildCore
//import SPMTestSupport
//import SwiftDriver
import TSCBasic
@testable import TSCUtility

struct MockToolchain: PackageModel.Toolchain {
    let swiftCompilerPath = AbsolutePath("/fake/path/to/swiftc")
    let extraCCFlags: [String] = []
    let extraSwiftCFlags: [String] = []
    #if os(macOS)
    let extraCPPFlags: [String] = ["-lc++"]
    #else
    let extraCPPFlags: [String] = ["-lstdc++"]
    #endif
    func getClangCompiler() throws -> AbsolutePath {
        return AbsolutePath("/fake/path/to/clang")
    }

    func _isClangCompilerVendorApple() throws -> Bool? {
      #if os(macOS)
        return true
      #else
        return false
      #endif
    }
}


extension TSCUtility.Triple {
    static let x86_64Linux = try! Triple("x86_64-unknown-linux-gnu")
    static let arm64Linux = try! Triple("aarch64-unknown-linux-gnu")
    static let arm64Android = try! Triple("aarch64-unknown-linux-android")
    static let windows = try! Triple("x86_64-unknown-windows-msvc")
    static let wasi = try! Triple("wasm32-unknown-wasi")
}

extension AbsolutePath {
    func escapedPathString() -> String {
        return self.pathString.replacingOccurrences(of: "\\", with: "\\\\")
    }
}

let hostTriple = UserToolchain.default.triple
#if os(macOS)
    let defaultTargetTriple: String = hostTriple.tripleString(forPlatformVersion: "10.10")
#else
    let defaultTargetTriple: String = hostTriple.tripleString
#endif

func mockBuildParameters(
    buildPath: AbsolutePath = AbsolutePath("/path/to/build"),
    config: BuildConfiguration = .debug,
    toolchain: PackageModel.Toolchain = MockToolchain(),
    flags: BuildFlags = BuildFlags(),
    shouldLinkStaticSwiftStdlib: Bool = false,
    canRenameEntrypointFunctionName: Bool = false,
    destinationTriple: TSCUtility.Triple = hostTriple,
    indexStoreMode: BuildParameters.IndexStoreMode = .off,
    useExplicitModuleBuild: Bool = false,
    linkerDeadStrip: Bool = true
) -> BuildParameters {
    return BuildParameters(
        dataPath: buildPath,
        configuration: config,
        toolchain: toolchain,
        hostTriple: hostTriple,
        destinationTriple: destinationTriple,
        flags: flags,
        jobs: 3,
        shouldLinkStaticSwiftStdlib: shouldLinkStaticSwiftStdlib,
        canRenameEntrypointFunctionName: canRenameEntrypointFunctionName,
        indexStoreMode: indexStoreMode,
        useExplicitModuleBuild: useExplicitModuleBuild,
        linkerDeadStrip: linkerDeadStrip
    )
}

func mockBuildParameters(environment: BuildEnvironment) -> BuildParameters {
    let triple: TSCUtility.Triple
    switch environment.platform {
    case .macOS:
        triple = Triple.macOS
    case .linux:
        triple = Triple.arm64Linux
    case .android:
        triple = Triple.arm64Android
    case .windows:
        triple = Triple.windows
    default:
        fatalError("unsupported platform in tests")
    }

    return mockBuildParameters(config: environment.configuration, destinationTriple: triple)
}
