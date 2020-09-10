load("@io_bazel_rules_kotlin//kotlin:kotlin.bzl", "kt_jvm_library")

_STRING_TYPE = "String"
_BOOLEAN_TYPE = "Boolean"
_INT_TYPE = "Int"
_LONG_TYPE = "Long"

def _build_statement(type, items, quote = True):
    statements = ""
    for variable_name, value in items.items():
        if quote:
            value = "\"{}\"".format(value)
        if type == _BOOLEAN_TYPE:
            value = "{}.toBoolean()".format(value)

        statements += """
    @JvmStatic
    val {}: {} = {}""".format(variable_name, type, value)
    return statements

def build_config(
        name,
        package_name,
        strings = {},
        booleans = {},
        ints = {},
        longs = {}):
    """Generates a Jar file containing BuildConfig class just like AGP.

    Usage:
    Add the field variables in the relevant dicts like (strings, booleans etc) and add a dependency
    on this targets name + _lib. For example, if the build_config name is build_config then the
    target to depend on from android_library or android_binary will be build_config_lib.

    Args:
        name: Name for this target
        package_name: Package name of the generated build file. Same as the android_binary or android_library
        strings: Build config field of type String
        booleans: Build config field of type Boolean
        ints: Build config field of type Int
        longs: Build config field of type longs
    """

    build_config = "BuildConfig"
    build_config_file_path = "$(RULEDIR)/{}.kt".format(build_config)

    # Uses srcjar so that the generated .kt file can be compiled to class file via kt_jvm_library
    build_config_jar = name + ".srcjar"

    strings_statements = _build_statement(_STRING_TYPE, strings)
    booleans_statements = _build_statement(
        _BOOLEAN_TYPE,
        dict(booleans, DEBUG = "true"),
    )
    ints_statements = _build_statement(_INT_TYPE, ints, False)
    longs_statements = _build_statement(_LONG_TYPE, longs, False)

    # Cmd for genrule. Generates BuildConfig.kt and packages it to a Java jar file in the build
    # directory
    cmd = """
cat << EOF > {build_config_file_path}
/**
 * Generated file do not modify
 */
package {package_name}
object {build_config} {{
    // Generated custom fields
    {strings_statements}
    {booleans_statements}
    {ints_statements}
    {longs_statements}
}}
EOF
$(JAVABASE)/bin/jar -cf $@ {build_config_file_path}
rm {build_config_file_path}
""".format(
        build_config = build_config,
        build_config_file_path = build_config_file_path,
        package_name = package_name,
        strings_statements = strings_statements,
        booleans_statements = booleans_statements,
        ints_statements = ints_statements,
        longs_statements = longs_statements,
    )

    native.genrule(
        name = name,
        outs = [build_config_jar],
        cmd = cmd,
        toolchains = ["@bazel_tools//tools/jdk:current_java_runtime"],
    )

    kt_jvm_library(
        name = name + "_lib",
        srcs = [build_config_jar],
    )
