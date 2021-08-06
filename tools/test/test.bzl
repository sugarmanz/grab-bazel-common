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
        associates: associates target to allow access to internal members from the main target
    """
    _gen_test_targets(
        test_compile_rule_type = kt_jvm_library,
        test_runner_rule_type = native.android_local_test,
        name = name,
        srcs = srcs,
        associates = associates,
        deps = deps,
        runner_associates = False,
        test_compile_deps = [
            "@maven//:org_robolectric_robolectric",
            "@robolectric//bazel:android-all",
        ],
        test_runner_deps = [],
        **kwargs
    )

def grab_kt_jvm_test(
        name,
        srcs,
        deps,
        associates = [],
        **kwargs):
    """A macro generates test targets to execute kotlin library unit tests. The macro is an abstraction between unit test info (srcs, deps, etc.) and any approaches to run unit tests.

    Usage:
    The macro will generate:
      - an kt_jvm_library target, containing all sources and dependencies
      - multiple kt_jvm_test targets based on each *Test file present in the srcs. The logic makes the below
        assumptions
        - Kotlin file that ends with Test
        - Package name, class name matches the actual file path and file name on disk.


    Args:
        name: name for this target,
        deps: the build dependencies to use for the generated local test
        and all valid arguments that you want to pass to the kt_jvm_test target
    """
    _gen_test_targets(
        test_compile_rule_type = kt_jvm_library,
        test_runner_rule_type = kt_jvm_test,
        name = name,
        srcs = srcs,
        associates = associates,
        deps = deps,
        test_compile_deps = [
            "@com_github_jetbrains_kotlin//:kotlin-test",
        ],
        test_runner_deps = [
            "@com_github_jetbrains_kotlin//:kotlin-test",
        ],
        **kwargs
    )

def _gen_test_targets(
        test_compile_rule_type,
        test_runner_rule_type,
        name,
        srcs,
        deps,
        test_compile_deps,
        test_runner_deps,
        runner_associates = True,
        associates = [],
        **kwargs):
    jvm_lib_name = name

    test_compile_rule_type(
        name = jvm_lib_name,
        srcs = srcs,
        deps = deps + test_compile_deps,
        associates = associates,
    )

    # Kt jvm test complains when no sources are given but deps are given, pass a dummy file
    trigger = "trigger"
    native.genrule(
        name = trigger,
        outs = ["Trigger.kt"],
        cmd = """echo "" > $@""",
    )

    for src in srcs:
        if src.endswith("Test.kt"):
            # src/main/java/com/grab/test/TestFile.kt
            path_split = src.rpartition("/")  # [src/main/java/com/grab/test,/,TestFile.kt]

            test_file = path_split[2]  # Testfile.kt
            test_target_name = test_file.split(".")[0]

            # Find package name from path
            path = path_split[0]  # src/main/java/com/grab/test
            test_package = ""
            if path.find("src/test/java/") != -1:
                path = path.split("src/test/java/")[1]  # com/grab/test
                test_class = path.replace("/", ".") + "." + test_target_name  # com.grab.test.TestFile

                if runner_associates:
                    test_runner_rule_type(
                        name = test_class.replace(".","_"),
                        srcs = [trigger],
                        test_class = test_class,
                        deps = [
                            ":" + jvm_lib_name,
                        ] + test_runner_deps,
                        associates = associates,
                        **kwargs
                    )
                else: 
                    test_runner_rule_type(
                        name = test_class.replace(".","_"),
                        test_class = test_class,
                        deps = [
                            ":" + jvm_lib_name,
                        ] + test_runner_deps,
                        **kwargs
                    )
