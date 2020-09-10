"""
Macro for supporting custom resource set typically defined in Gradle via source sets.

Bazel expects all resources to be in same root `res` directory but Gradle does not have this
limitation. This macro receives directory on file system and copies the required resources to
Bazel compatible `res` folder during build.
"""

def custom_res(target, dir_name, resource_files = []):
    """
    This macro make sures the given `resource_files` are present in a bazel compatible folder by
    copying them to correct directory.

    Args:
      target: The label of the target for which resources should be made compatible.
      dir_name: The root name of the folder which needs to be fixed i.e the one that is not `res`
      resource_files: The list of files that should be copied to. Usually a result of `glob` function.

    Returns:
      A list of generated resource_files in the correct `res` directory that can be specified as
      input to android_library or android_binary rules
    """
    new_root_dir = target + "_" + dir_name
    fixed_resource_path = []
    for old_resource_path in resource_files:
        fixed_path = new_root_dir + "/" + old_resource_path.replace("/" + dir_name, "/res")
        fixed_resource_path.append(fixed_path)
        genrule_suffix = old_resource_path.replace("/", "_").replace(".", "_").replace("-", "_")
        native.genrule(
            name = "_" + target + "_" + genrule_suffix,
            srcs = [old_resource_path],
            outs = [fixed_path],
            cmd = "cp $< $@",
        )
    return fixed_resource_path
