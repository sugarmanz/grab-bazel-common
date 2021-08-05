load("@io_bazel_rules_kotlin//kotlin:kotlin.bzl", "kt_jvm_library", "kt_jvm_test")


def grab_android_local_test(name, srcs, deps, associates = [], **kwargs):
    """A macro generates test targets to execute all android library unit tests. The macro is an abstraction between unit test info (srcs, deps, etc.) and any approaches to run unit tests.

    Usage:
    The macro will generate:
      - an android_library target, containing all sources and dependencies
      - the android_library target will add the test-suite-generator (annotation processor) to generate a test suite that contains all test classes
      - an android_local_test target for the whole sources package, and set the test suite class as the test_class

    Args:
        name: name for the test target,
        srcs: the test sources under test.
        deps: the build dependencies to use for the generated the android local test target
        and all valid arguments that you want to pass to the android_local_test target
    """
    jvm_lib_name = name + "-lib"
    kt_jvm_library(
        name = jvm_lib_name,
        srcs = srcs,
        associates = associates,
        deps = deps + [
            "@maven//:org_robolectric_robolectric",
            "@robolectric//bazel:android-all",
            "@grab_bazel_common//tools/test-suite-generator:test-suite-generator",
        ],
    )

    native.android_local_test(
        name = name,
        test_class = "com.grazel.generated.TestSuite",
        deps = [":" + jvm_lib_name],
        **kwargs
    )

def grab_kt_jvm_test(
        name,
        deps,
        **kwargs):
    """A macro generates test targets to execute kotlin library unit tests. The macro is an abstraction between unit test info (srcs, deps, etc.) and any approaches to run unit tests.

    Usage:
    The macro will generate:
      - an kt_jvm_test target, containing all sources and dependencies
      - an android_library target will add the test-suite-generator (annotation processor) to generate a test suite that contains all test classes

    Args:
        name: name for this target,
        deps: the build dependencies to use for the generated local test
        and all valid arguments that you want to pass to the kt_jvm_test target
    """
    kt_jvm_test(
        name = name,
        test_class = "com.grazel.generated.TestSuite",
        deps = deps + [
            "@com_github_jetbrains_kotlin//:kotlin-test",
            "@grab_bazel_common//tools/test-suite-generator:test-suite-generator",
        ],
        **kwargs
    )