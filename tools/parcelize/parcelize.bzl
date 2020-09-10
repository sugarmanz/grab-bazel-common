load("@io_bazel_rules_kotlin//kotlin:kotlin.bzl", "kt_compiler_plugin", "kt_jvm_library")

def parcelize_rules():
    """Create Kotlin parcelize rules

    Usage:
    This macro will create an "parcelize" target, which is a kt_compiler_plugin. You can apply this rule to your project by referring to it as //:android-extensions
    in deps. The target automatically exports runtime dependencies needed for the plugin.
    For example:

    kt_android_library(
        name = "lib",
        resource_files = glob(["src/main/res/**",]),
        custom_package = "your.package",
        manifest = "src/main/AndroidManifest.xml",
        visibility = ["//visibility:public"],
        srcs = glob(["src/main/java/**/*.kt"]),
        deps = ["//:android-extensions"],
    )

    """
    kt_compiler_plugin(
        name = "parcelize_plugin",
        id = "org.jetbrains.kotlin.parcelize",
        compile_phase = True,
        stubs_phase = False,
        target_embedded_compiler = True,
        deps = [
            "@maven//:org_jetbrains_kotlin_kotlin_parcelize_compiler",
        ],
    )

    kt_jvm_library(
        name = "parcelize",
        exported_compiler_plugins = [":parcelize_plugin"],
        visibility = ["//visibility:public"],
        exports = [
            "@maven//:org_jetbrains_kotlin_kotlin_parcelize_runtime",
        ],
    )
