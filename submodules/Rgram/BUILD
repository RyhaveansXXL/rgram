load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")
load("@build_bazel_rules_apple//apple:ios.bzl", "ios_unit_test")
load("@build_bazel_rules_apple//apple/testing/default_runner:ios_test_runner.bzl", "ios_test_runner")

swift_library(
    name = "RGram",
    module_name = "RGram",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    copts = [
        "-warnings-as-errors",
    ],
    deps = [],
    visibility = [
        "//visibility:public",
    ],
)

swift_library(
    name = "RGramTestsLib",
    testonly = True,
    srcs = glob([
        "Tests/**/*.swift",
    ]),
    deps = [
        ":RGram",
    ],
)

ios_test_runner(
    name = "RGramTestRunner",
    device_type = "iPhone 17",
    os_version = "26.5",
)

ios_unit_test(
    name = "RGramTests",
    minimum_os_version = "15.0",
    runner = ":RGramTestRunner",
    deps = [
        ":RGramTestsLib",
    ],
    visibility = [
        "//visibility:public",
    ],
)
