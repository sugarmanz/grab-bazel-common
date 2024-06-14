def dagger_rules(repo_name = "@maven"):
    """Defines the Dagger targets with proper exported dependencies and plugins.

    The targets will be of the form ":<artifact-id>".

    Args:
      repo_name: The name of the dependency repository (default is "@maven").
    """
    native.java_library(
        name = "dagger",
        exported_plugins = [":dagger-compiler"],
        visibility = ["//visibility:public"],
        exports = [
            "%s//:com_google_dagger_dagger" % repo_name,
            "%s//:javax_inject_javax_inject" % repo_name,
        ],
    )

    native.java_plugin(
        name = "dagger-compiler",
        generates_api = 1,
        processor_class = "dagger.internal.codegen.ComponentProcessor",
        deps = [
            "%s//:com_google_dagger_dagger_compiler" % repo_name,
        ],
    )

    native.java_library(
        name = "dagger-producers",
        visibility = ["//visibility:public"],
        exports = [
            ":dagger",
            "%s//:com_google_dagger_dagger_producers" % repo_name,
        ],
    )

    native.java_library(
        name = "dagger-spi",
        visibility = ["//visibility:public"],
        exports = [
            "%s//:com_google_dagger_dagger_spi" % repo_name,
        ],
    )
