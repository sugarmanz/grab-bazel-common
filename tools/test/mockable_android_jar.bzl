def mockable_android_jar():
    """
    Create an mockable version of Android SDK Jar.

    This is done to mimick Android Gradle Plugin's mocked Android Jar feature for tests
    https://developer.android.com/training/testing/unit-testing/local-unit-tests#mocking-dependencies
    All methods will return default and null values when invoked at test runtime.

    Usage:
    Call mockable_android_jar() in desired BUILD file and add a dependency on
    @grab_bazel_common//tools/test:mockable-android-jar to use android classes in unit tests

    """
    _mockable_jar_generator = "@grab_bazel_common//tools/mockable-jar-generator:mockable-jar-generator"
    _android_jar = "@bazel_tools//tools/android:android_jar"
    _android_mock_jar = "android_mock.jar"

    native.genrule(
        name = "mockable-android-jar-generator",
        srcs = [_android_jar],
        outs = [
            _android_mock_jar,
        ],
        tools = [_mockable_jar_generator],
        toolchains = ["@bazel_tools//tools/jdk:current_java_runtime"],
        cmd = """
            $(location {mockable_jar_generator}) \
            --input-jar $< \
            --output-jar $@
            """.format(
            android_jar = _android_jar,
            mockable_jar_generator = _mockable_jar_generator,
            android_mock_jar = _android_mock_jar,
        ),
    )

    name = "mockable-android-jar"
    native.java_import(
        name = name,
        visibility = [
            "//visibility:public",
        ],
        jars = [
            _android_mock_jar,
        ],
    )
