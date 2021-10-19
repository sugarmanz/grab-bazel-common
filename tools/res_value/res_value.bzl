def _res_statement(items):
    statements = ""
    for variable_name, value in items.items():
        statements += """
        <string name=\\"{}\\">{}</string>""".format(variable_name, value)
    return statements

def _generate_xml(items):
    statements = """<?xml version=\\"1.0\\" encoding=\\"utf-8\\"?>
<resources>{}
</resources>
    """
    return statements.format(items)

def res_value(
        name,
        custom_package,
        manifest,
        strings = {}):
    """Generates an android library target that exposes values specified in strings
    as generated resources xml.

    Usage:
    Provide the string variables in the string dictionary and add a dependency on this target.

    Args:
        name: name for this target,
        custom_package: package used for Android resource processing,
        manifest: required when resource_files are defined,
        strings: string value of type string
    """

    res_value_file = "src/main/res/values/gen_strings.xml"
    strings_statements = _res_statement(strings)
    xml_generation = _generate_xml(strings_statements)

    cmd = """echo "{xml_generation}" > $@""".format(xml_generation = xml_generation)

    native.genrule(
        name = "_" + name,
        outs = [res_value_file],
        message = "Generating %s's resources" % (native.package_name()),
        cmd = cmd,
    )

    native.android_library(
        name = name,
        manifest = manifest,
        custom_package = custom_package,
        resource_files = [res_value_file],
    )
