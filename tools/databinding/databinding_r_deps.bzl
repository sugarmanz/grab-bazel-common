"""
A rule to extract R.txt directly from android_library rule by talking to its provider.
"""

_R_TXT_ZIP = "r_txt_dep.zip"

def _extract_r_txt_deps(ctx):
    """
    A rule to extract R.txt files as zip from android_library targets appearing as direct
    dependencies in the deps.
    """
    deps = ctx.attr.deps
    package = ctx.attr.package
    merged_r_txt_zip = ctx.outputs.r_txt_zip
    merged_r_txt_dir = ctx.actions.declare_directory("r_txts")

    array_r_txt = []

    for target in deps:
        if (AndroidResourcesInfo in target):
            android_resources_info = target[AndroidResourcesInfo]
            r_txt_file = android_resources_info.compiletime_r_txt
            array_r_txt.append(r_txt_file)

    ctx.actions.run_shell(
        inputs = array_r_txt,
        outputs = [merged_r_txt_dir],
        progress_message = "Extracting %s's direct R.txt from deps" % (package),
        mnemonic = "ExtractRTxtDeps",
        command = ("mkdir -p %s\n" % (merged_r_txt_dir.path)) +
                  "\n".join([
                      "cp %s %s" % (r_file.path, merged_r_txt_dir.path + "/copied%sR.txt" % (index))
                      for index, r_file in enumerate(array_r_txt)
                  ]),
    )

    ctx.actions.run_shell(
        inputs = [merged_r_txt_dir],
        outputs = [merged_r_txt_zip],
        progress_message = "Merging %s's direct R.txt from deps" % (package),
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
        "package": attr.string(mandatory = True),
        "deps": attr.label_list(),
        "_zipper": attr.label(
            default = Label("@bazel_tools//tools/zip:zipper"),
            cfg = "exec",
            executable = True,
        ),
    },
    outputs = {"r_txt_zip": _R_TXT_ZIP},
)
