load("@io_bazel_rules_kotlin//kotlin:kotlin.bzl", "kt_jvm_library")
load("@io_bazel_rules_kotlin//kotlin:kotlin.bzl", "kt_jvm_test")

def grab_android_local_test(name, srcs, deps, associates = [], **kwargs):
    """A macro generates test targets to execute all android library unit tests.

    Usage:
    The macro creates a single build target to compile all Android unit test classes and then creates
    multiple parallel test targets for each Test class. The name of the test class is derived from
    test class name and location of the file disk

    Args:
        name: name for the test target,
        srcs: the test sources under test.
        deps: the build dependencies to use for the generated the android local test target
        and all valid arguments that you want to pass to the android_local_test target
        associates: associates target to allow access to internal members from the main Kotlin target
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
    """A macro generates test targets to execute all Kotlin unit tests.

    Usage:
        The macro creates a single build target to compile all Android unit test classes and then creates
        multiple parallel test targets for each Test class. The name of the test class is derived from
        test class name and location of the file disk

    Args:
        name: name for the test target,
        srcs: the test sources under test.
        deps: the build dependencies to use for the generated the android local test target
        and all valid arguments that you want to pass to the android_local_test target
        associates: associates target to allow access to internal members from the main Kotlin target
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
    """A macro to auto generate and compile and runner targets for tests.

    Usage:
        The macro works under certain assumptions and only works for Kotlin files. The macro builds
        all test sources in a single target specified by test_compile_rule_type and then generates
        parallel runner targets with test_runner_rule_type.
        In order for this to function correctly, the Kotlin test file and the class name should be the
        same and package name of test class should mirror the location of the file on disk.

    Args:
    test_compile_rule_type: The rule type that will be used for compiling test sources
    test_runner_rule_type: The rule type that will be used for running test targets
    name: name of the target
    srcs: All test sources, mixed Java and Kotlin are supported during build phase but only Kotlin is
    supported in runner phase.
    deps: All dependencies required for building test sources
    test_compile_deps: Any dependencies required for the build target.
    test_runner_deps: Any dependencies required for the test runner target.
    runner_associates: If set, will forward associates flag to the runner target.
    associates: The list of associate targets to allow access to internal members.
    """
    jvm_lib_name = name + "_build"

    test_compile_rule_type(
        name = jvm_lib_name,
        srcs = srcs,
        deps = deps + test_compile_deps,
        associates = associates,
    )

    test_names = []
    for src in srcs:
        if src.endswith("Test.kt") or src.endswith("Tests.kt"):
            # src/test/java/com/grab/test/TestFile.kt
            path_split = src.rpartition("/")  # [src/test/java/com/grab/test,/,TestFile.kt]

            test_file = path_split[2]  # Testfile.kt
            test_file_name = test_file.split(".")[0]  # Testfile

            # Find package name from path
            path = path_split[0]  # src/main/java/com/grab/test
            
            test_package = ""
            if path.find("src/test/java/") != -1 or path.find("src/test/kotlin/") != -1:  # TODO make this path configurable
                path = path.split("src/test/java/")[1] if path.find("src/test/java/") != -1 else path.split("src/test/kotlin/")[1] # com/grab/test
                test_class = path.replace("/", ".") + "." + test_file_name  # com.grab.test.TestFile

                test_target_name = test_class.replace(".", "_")
                test_names.append(test_target_name)

                # Kt jvm test complains when no sources are given but deps are given, so pass a dummy
                # file to act as trigger
                trigger = "_" + test_target_name + "_trigger"
                native.genrule(
                        name = trigger,
                        outs = [test_target_name + "_Trigger.kt"],
                        cmd = """echo "" > $@""",
                )

                if runner_associates:
                    test_runner_rule_type(
                        name = test_target_name,
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
                        name = test_class.replace(".", "_"),
                        test_class = test_class,
                        deps = [
                            ":" + jvm_lib_name,
                        ] + test_runner_deps,
                        **kwargs
                    )

    if len(test_names) >= 0:
        native.test_suite(
            name = name,
            tests = test_names,
        )
