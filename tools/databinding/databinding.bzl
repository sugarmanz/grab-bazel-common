load("@io_bazel_rules_kotlin//kotlin:kotlin.bzl", "kt_android_library")
load(":databinding_aar.bzl", "databinding_aar")
load(":databinding_classinfo.bzl", "direct_class_infos")
load("@io_bazel_rules_kotlin//kotlin:kotlin.bzl", "kt_jvm_library")
load(":databinding_r_deps.bzl", "extract_r_txt_deps")

DATABINDING_DEPS = [
    "@maven//:androidx_databinding_databinding_adapters",
    "@maven//:androidx_databinding_databinding_common",
    "@maven//:androidx_databinding_databinding_runtime",
    "@maven//:androidx_annotation_annotation",
]

_binding_stub_target = "@grab_bazel_common//tools/db-compiler-lite:db-compiler-lite"
_r_classes = "r-classes"
_binding_classes_jar = "binding-classes.srcjar"
_zipper = "@bazel_tools//tools/zip:zipper"

def _databinding_stubs(
        name,
        custom_package,
        manifest = None,
        resource_files = [],
        deps = []):
    """
    This macro registers collection of rules to compile Databinding stub classes like R.java, BR.java
    and other *Binding classes.

    It works by excluding all layout resources in `resource_files` and then compiling them with
    android_library to generate R class for all other resources.
    Then, all layout resources are passed to `_binding_stub_target` to generate all the remaining
    R and binding classes.
    Additionally it mimics AAPT by generating R.txt from dependencies and current module resources.

    Args:
        name: Name for the target that uses the stubs
        custom_package: Custom package for the target.
        manifest: The AndroidManifest.xml file for android library.
        resource_files: The resource files for the target
        deps: The dependencies for the whole target.

    Outputs:
        r-classes: The R and BR classes
        binding-classes.srcjar: All the databinding *Binding classes
    """

    # Filter out layout resources to generate Binding classes
    layout_resources = []
    for resource in resource_files:
        if resource.find("/layout") != -1:
            layout_resources.append(resource)

    # Collect all the layout files as filegroup so that Bazel can register them as inputs
    layout_filegroup = name + "-layout-files"
    native.filegroup(
        name = layout_filegroup,
        srcs = layout_resources,
    )

    res_filegroup = name + "-res-files"
    native.filegroup(
        name = res_filegroup,
        srcs = resource_files,
    )

    # Collect all direct classInfo files to infer databinding layouts in dependencies.
    class_infos = "_class_infos"
    direct_class_infos(
        name = class_infos,
        deps = deps,
    )

    # Extract R.txt for every dependency aar to generate joined R.java for a module.
    r_txt_zip = "_r_txt_zip"
    extract_r_txt_deps(
        name = r_txt_zip,
        libs = deps,
    )

    # Prepare --layout argument for binding stub generator which passes all layout files as
    # list to stub generator
    layouts_arg = ""
    if len(layout_resources) > 0:
        layouts_arg = "--layouts " + ",".join(layout_resources)

    res_arg = ""
    if len(resource_files) > 0:
        res_arg = "--resources " + ",".join(resource_files)

    r_classes_src = _r_classes + ".srcjar"

    # Generate stub classes that Databinding would generate.
    # TODO: Convert this to rule
    native.genrule(
        name = name + "-generator",
        srcs = [
            r_txt_zip,
            ":" + res_filegroup,
            # We add layout files as input to ensure the genrule runs again when
            # files are changed.
            ":" + layout_filegroup,
            class_infos,
        ],
        outs = [
            r_classes_src,
            _binding_classes_jar,
        ],
        tools = [
            _binding_stub_target,
            "@bazel_tools//tools/zip:zipper",
        ],
        toolchains = ["@bazel_tools//tools/jdk:current_java_runtime"],
        cmd = """
        cp $(location {class_infos}) class_infos.zip
        cp $(location {r_txt_dep}) r_txt_dep.zip

        $(location {_binding_stub_target}) \
        --src {src} \
        --package {package} \
        --class-info class_infos.zip \
        --r-txt-deps r_txt_dep.zip \
        {layouts} \
        {resources} 

        find r-classes -type f -exec $(location {zipper}) c $(location :{r_classes}) {{}} +
        find db-stubs -type f -exec $(location {zipper}) c $(location :{binding_classes}) {{}} +
        """.format(
            layouts = layouts_arg,
            r_txt_dep = r_txt_zip,
            resources = res_arg,
            _binding_stub_target = _binding_stub_target,
            package = custom_package,
            r_classes = r_classes_src,
            binding_classes = _binding_classes_jar,
            src = native.package_name(),
            class_infos = class_infos,
            zipper = _zipper,
        ),
    )

    # R classes are not meant to be packaged into the binary, so export it as java_library but don't
    # link it.
    native.java_library(
        name = _r_classes,
        srcs = [r_classes_src],
        neverlink = 1,  # Use the R classes only for compiling and not at runtime.
    )

def _filter_deps(deps):
    """Filters known dependency labels that are not needed for databinding compilation
    """
    results = []
    for dep in deps:
        # TODO This ideally should be filtered via rules and checking for plugin providers
        if dep != "//:dagger":
            results.append(dep)
    return results

def kt_db_android_library(
        name,
        srcs = [],
        custom_package = None,
        manifest = None,
        resource_files = [],
        assets = None,
        assets_dir = None,
        deps = [],
        plugins = [],
        visibility = None,
        tags = []):
    """Configures rules for compiling android module that uses Databinding and Kotlin.

    The macro ensures that Kotlin code referenced in any XMLs are compiled first using kt_android_library
    and then uses android_library's enable_data_binding to generate required Databinding classes.

    This helps in breaking circular dependency when we have android_library (databinding enabled) -> kt_android_library. 
    In that case, Databinding classes can't be generated until resources are processed and that happens only in android_library 
    target. So compiling Koltin classes becomes dependent on android_library and android_library depends on kt_android_library since
    it needs class files to process class references in XML. This macro alleviates this problem by processing resources without
    android resources or `aapt` via a custom compiler and generates stub classes like R.java, BR.java and *Binding.java. 

    Then Kotlin code can be safely compiled without errors. In the final stage, the stub classes are replaced with actual classes by 
    android_library target. 

    It also supports @BindingAdapters written in Kotlin.

    Args:
        name: The name of the target.
        srcs: Kotlin and Java classes for the target.
        custom_package: Custom package for the target. Forwards to 'kt_|android_library'.
        manifest: The AndroidManifest.xml file for android library.
        assets: Assets for android_library rule
        assets_dir: Assets dir for android_library rule
        resource_files: The resource files for the target.
        deps: The dependencies for the whole target.
        plugins: Kotlin compiler plugins for internal Kotlin target
        visibility: Visibility of the target.
        tags: Tags for both Kotlin and Android resources target.
    """

    # Create R.java and stub classes for classes that Android databinding and AAPT would produce
    # so that we can compile Kotlin classes first without errors
    databinding_stubs = name + "-stubs"
    _databinding_stubs(
        name = databinding_stubs,
        custom_package = custom_package,
        manifest = manifest,
        resource_files = resource_files,
        deps = deps + DATABINDING_DEPS,
    )

    # Create an intermediate target for compiling all Kotlin classes used in Databinding
    kotlin_target = name + "-kotlin"
    kotlin_targets = []

    # List for holding binding adapter sources
    binding_adapter_sources = []

    if len(srcs) > 0:
        # Compile all Kotlin classes first with the stubs generated earlier. The stubs are provided
        # as srcs in _binding_classes_jar. This would allow use to compile Kotlin classes successfully
        # since stubs will allow compilation to proceed without errors related to missing binding classes.
        #
        # Additionally, run our custom annotation processor "binding-adapter-bridge" that would generate
        # .java files for Kotlin @BindingAdapter.

        kt_jvm_library(
            name = kotlin_target,
            srcs = srcs + [_binding_classes_jar],
            plugins = plugins,
            deps = deps + DATABINDING_DEPS + [_r_classes] + [
                "@grab_bazel_common//tools/binding-adapter-bridge:binding-adapter-bridge",
                "@grab_bazel_common//tools/android:android_sdk",
            ],
            tags = tags,
        )
        kotlin_targets.append(kotlin_target)

        # The Kotlin target would run binding-adapter annotation processor and package the Java proxy
        # classes as a jar file, BUT android_library does not run data binding annotation processor
        # if classes are present inside jar i.e deps. To overcome this, we repackage sources jar into
        # .srcjar so that we can feed it to android_library's `srcs` to force data binding processor
        # to run.
        # Additionally we clean up all extra files that might be present in the sources.jar. The
        # jar should purely contain *_Binding_Adapter_Stub.java files.
        #
        # This step can be probably be avoided when https://github.com/bazelbuild/bazel/issues/11745
        # is fixed.
        binding_adapters_source = name + "-binding-adapters"
        native.genrule(
            name = binding_adapters_source,
            srcs = [":" + kotlin_target + "-sources.jar"],
            outs = [kotlin_target + "_kt-sources.srcjar"],
            tools = ["@bazel_tools//tools/zip:zipper"],
            cmd = """
            TEMP="adapter-sources"
            mkdir -p $$TEMP
            unzip -q -o $< -d $$TEMP/
            find $$TEMP/. -type f ! -name '*_Binding_Adapter_Stub.java' -delete
            touch $$TEMP/empty.txt # Package empty file to ensure jar file is always generated
            find $$TEMP/. -type f -exec $(location {zipper}) c $(OUTS) {{}} +
            rm -rf $$TEMP
            """.format(zipper = _zipper),
        )
        binding_adapter_sources.append(binding_adapters_source)

    # Data binding target responsible for generating Databinding related classes.
    # By the time this is compiled:
    # * Kotlin classes are already available via deps. So resources processing is safe.
    # * Kotlin @BindingAdapters are converted to Java via our annotation processor
    # * Our stub classes would be replaced by android_library's actual generated code.
    native.android_library(
        name = name,
        srcs = binding_adapter_sources,
        custom_package = custom_package,
        enable_data_binding = True,
        resource_files = resource_files,
        assets = assets,
        assets_dir = assets_dir,
        visibility = visibility,
        manifest = manifest,
        tags = tags,
        deps = kotlin_targets + _filter_deps(deps) + DATABINDING_DEPS,
        # Export the Kotlin target so that other databinding modules that depend on this module
        # can use classes defined in this module in their databinding generated classes.
        #
        # This is required since kt_android_library hides _kt target behind an android_library rule,
        # hence _kt target only appears are transitive dep instead of direct during databinding
        # generation in module A.
        # Graph:                +------+
        #                       |  kt  |
        #                       +------+
        #                          ^
        #       +--------+    +--------+
        #       |   A    +--->+   B    |
        #       +--------+    +--------+
        # A's databinding generated code can depend on B's kotlin code.
        # See: https://blog.bazel.build/2017/06/28/sjd-unused_deps.html
        # Can be also overcome by --strict_java_deps=warn
        exports = kotlin_targets,
    )

    # Package aar correctly for Gradle builds.
    # Disabled for now.
    # databinding_aar(
    #     name = name + "-databinding",
    #     android_library = name,
    #     kotlin_jar = kotlin_target + "_kt.jar",
    # )
