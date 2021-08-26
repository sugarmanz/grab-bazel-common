

def mockable_android_jar():
    """

    Usage:


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
            echo abcd
            $(location {mockable_jar_generator}) \
            --input-jar $< \
            --output-jar $@
            """.format(
                android_jar = _android_jar,
                mockable_jar_generator = _mockable_jar_generator,
                android_mock_jar = _android_mock_jar
            ),
        )

    native.java_import(
        name = "mockable-android-jar",
        visibility = [
                "//visibility:public",
            ],
        jars = [
            _android_mock_jar
         ],
    )