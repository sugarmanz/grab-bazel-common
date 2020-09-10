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
    """Generates a string xml file containing String values as AGP.

    Usage:
    Provide the String variables in the String dictionary and add a dependency
    on generated res target. For example, if the res_value name is app-res-value
    then the target to depend on will be app-res-value.

    Args:
        name: name for this target,
        custom_package: package used for Android resource processing,
        manifest: required when resource_files are defined,
        strings: String value of type String
    """

    res_value_file = "src/main/res/values/gen_strings.xml"
    strings_statements = _res_statement(strings)
    xml_generation = _generate_xml(strings_statements)

    # Cmd for genrule.
    cmd = """echo "{xml_generation}" > $@""".format(xml_generation = xml_generation)

    native.genrule(
        name = name + "-gen",
        outs = [res_value_file],
        cmd = cmd,
    )

    native.android_library(
        name = name,
        manifest = manifest,
        custom_package = custom_package,
        resource_files = [res_value_file],
    )
