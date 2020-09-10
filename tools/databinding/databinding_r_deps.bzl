"""
A rule to extract R.txt directly from android_library rule by talking to its provider.
"""

_R_TXT_ZIP = "r_txt_dep.zip"

def _extract_r_txt_deps(ctx):
    """
    A rule to extract R.txt directly from android_library targets.
    """
    deps = ctx.attr.libs
    merged_r_txt_zip = ctx.outputs.r_txt_zip
    merged_r_txt_dir = ctx.actions.declare_directory("r_txt_dir")

    array_r_txt = []

    for target in deps:
        if (AndroidResourcesInfo in target):
            androir_resources_info = target[AndroidResourcesInfo]
            r_txt_file = androir_resources_info.compiletime_r_txt
            array_r_txt.append(r_txt_file)

    ctx.actions.run_shell(
        inputs = array_r_txt,
        outputs = [merged_r_txt_dir],
        command = ("mkdir -p %s\n" % (merged_r_txt_dir.path)) +
                  "\n".join([
                      "cp %s %s" % (r_file.path, merged_r_txt_dir.path + "/copied%sR.txt" % (index))
                      for index, r_file in enumerate(array_r_txt)
                  ]),
    )

    ctx.actions.run_shell(
        inputs = [merged_r_txt_dir],
        outputs = [merged_r_txt_zip],
        progress_message = "Collecting all R.txt from dependencies to one ZIP",
        tools = [ctx.executable._zipper],
        mnemonic = "MergedRTxtDeps",
        command = """
        find -L {dir} -type f -exec {zipper_path} c {output} {{}} +
        """.format(
            zipper_path = ctx.executable._zipper.path,
            output = merged_r_txt_zip.path,
            dir = merged_r_txt_dir.path,
        ),
    )

extract_r_txt_deps = rule(
    implementation = _extract_r_txt_deps,
    attrs = {
        "libs": attr.label_list(),
        "_zipper": attr.label(
            default = Label("@bazel_tools//tools/zip:zipper"),
            cfg = "host",
            executable = True,
        ),
    },
    outputs = {"r_txt_zip": _R_TXT_ZIP},
)
