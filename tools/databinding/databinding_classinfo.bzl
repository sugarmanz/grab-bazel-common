load(":utils.bzl", "copy_file_action", "extract_binding_classes")

"""
A rule to collect content immediate deps' databinding classInfo.zip metadata files and merge them into
classInfo.zip
"""

_CLASS_INFOS = "class_infos.zip"

def _direct_class_infos(ctx):
    """
    Merges contents of databinding classInfo.zip into single zip.
    """
    merged_class_info_zip = ctx.outputs.class_infos
    merged_class_info_zip_dir = ctx.actions.declare_directory("class_infos")

    # In deps, filter targets that have databinding provider present
    deps = ctx.attr.deps
    class_infos = []
    for target in deps:
        if (DataBindingV2Info in target):
            data_binding_info = target[DataBindingV2Info]
            if len(data_binding_info.class_infos) > 0:
                class_infos.append(data_binding_info.class_infos[0])

    # Unzip all of them into common directory specified by merged_class_info_zip_dir
    ctx.actions.run_shell(
        inputs = class_infos,
        outputs = [merged_class_info_zip_dir],
        command = ("mkdir -p %s\n" % (merged_class_info_zip_dir.path)) +
                  "\n".join([
                      "unzip -q -o %s -d %s/" % (class_info.path, merged_class_info_zip_dir.path)
                      for class_info in class_infos
                  ]) +
                  # Add dummy file in generated folder to let the next Zipping action pass
                  # even when current target has no direct class info file
                  "\n touch %s/empty.txt" % (merged_class_info_zip_dir.path),
    )

    # Merge then into single zip specified by merged_class_info_zip
    ctx.actions.run_shell(
        inputs = [merged_class_info_zip_dir],
        outputs = [merged_class_info_zip],
        progress_message = "Merging direct databinding class infos",
        tools = [ctx.executable._zipper],
        mnemonic = "MergeDatabindingClassInfo",
        command = """
        # Use -L to follow symlinks
        find -L {dir} -type f -exec {zipper_path} c {output} {{}} +
        """.format(
            zipper_path = ctx.executable._zipper.path,
            dir = merged_class_info_zip_dir.path,
            output = merged_class_info_zip.path,
        ),
    )

direct_class_infos = rule(
    implementation = _direct_class_infos,
    attrs = {
        "deps": attr.label_list(),
        "_zipper": attr.label(
            default = Label("@bazel_tools//tools/zip:zipper"),
            cfg = "host",
            executable = True,
        ),
    },
    outputs = {"class_infos": _CLASS_INFOS},
)
