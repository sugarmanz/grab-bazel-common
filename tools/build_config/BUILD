load(":build_config.bzl", "build_config")
load("@io_bazel_rules_kotlin//kotlin:kotlin.bzl", "kt_jvm_test")

build_config(
    name = "build-config-sample",
    package_name = "com.grab.buildconfig.sample",
    booleans = {
        "TRUE": "true",
        "FALSE": "false",
        "STRING_BOOLEAN": "test",
    },
    ints = {
        "INT": "0",
    },
    longs = {
        "LONG": "123",
    },
    strings = {
        "SIMPLE_STRING": "Hello",
        "WITH_DOLLAR": "$$$$$$$$$$$$$",
        "SPECIAL_CHARACTERS": "!@#$%^&*()$",
        "FIELD_WITH_ESCAPED_DOLLAR": "\\$ Hello",
        "REWARD_URL": "https://reward.com/hc/%1$s/test",
    },
)

kt_jvm_test(
    name = "build-config-test",
    size = "small",
    srcs = [
        "src/test/java/com/grab/buildconfig/BuildConfigTests.kt",
    ],
    test_class = "com.grab.buildconfig.BuildConfigTests",
    deps = [
        ":build-config-sample",
        "@com_github_jetbrains_kotlin//:kotlin-test",
        "@maven//:junit_junit",
    ],
)

build_config(
    name = "build-config-replace-default",
    package_name = "com.grab.buildconfig.sample",
    strings = {
        "SIMPLE_STRING": "Hello",
        "VERSION_NAME": "1.2.3",
    },
)

kt_jvm_test(
    name = "build-config-replace-default-test",
    size = "small",
    srcs = [
        "src/test/java/com/grab/buildconfig/BuildConfigReplaceDefaultTests.kt",
    ],
    test_class = "com.grab.buildconfig.BuildConfigReplaceDefaultTests",
    deps = [
        ":build-config-replace-default",
        "@com_github_jetbrains_kotlin//:kotlin-test",
        "@maven//:junit_junit",
    ],
)
