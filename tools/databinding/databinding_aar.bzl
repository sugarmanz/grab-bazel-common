load(":utils.bzl", "copy_file_action", "extract_binding_classes")

"""
A rule to create aar file that merges Kotlin classes, Android resources and databinding metadata
such as classInfos, setter stores into a aar file so that it can be used by other build systems such
as Gradle.
"""

_DATABINDING = "databinding"
_BR = _DATABINDING + "/br"

def _clean_stubs_from_kotlin_jar(ctx, custom_package, source_kotlin_jar, output_kotlin_jar):
    """
    Deletes the following classes from the given jar file and creates a new jar file.
       DataBindingInfo.class
       DataBindingComponent.class
       custom_package/databinding/**
    """
    ctx.actions.run_shell(
        inputs = [source_kotlin_jar],
        outputs = [output_kotlin_jar],
        progress_message = "Cleaning stub classes from Kotlin jar: %s" % source_kotlin_jar.basename,
        command = """
         TEMP="$$(mktemp -d)"
         unzip -q -o {source_kotlin_jar} -d $$TEMP/
         find $$TEMP/. -type f -name 'DataBindingInfo.class' -delete
         find $$TEMP/. -type f -name 'DataBindingComponent.class' -delete
         find $$TEMP/{databinding_stub_path} -type f -name '*Binding.class' -delete
         find $$TEMP/. -type d -empty -delete
         jar=$(pwd)/{output_kotlin_jar}
         cd $$TEMP; zip -q -r temp.jar .
         cp temp.jar $jar
         """.format(
            source_kotlin_jar = source_kotlin_jar.path,
            output_kotlin_jar = output_kotlin_jar.path,
            databinding_stub_path = "/".join(custom_package.split(".")) + "/databinding/",
        ),
    )

def _package_aar(ctx, android_lib_name, setter_store_files, br_files, binding_classes_files, cleaned_kotlin_jar, source_aar, output_aar):
    """
    Registers couple of actions that creates the final databinding aar as expected by Gradle/Bazel.

    * Puts setter store files to /data-binding/
    * BR files to /data-binding/
    * Binding classes json files to /data-binding-base-class-log/
    * Clean excessive classes from Jar file such as
      * BR.class
      * DataBindingInfo.class
      * DataBindingComponent.class
    """
    cleaned_aar_file = ctx.actions.declare_file(android_lib_name + "-db-intermediate.aar")
    ctx.actions.run_shell(
        inputs = setter_store_files + br_files + binding_classes_files + [source_aar] + [cleaned_kotlin_jar],
        outputs = [cleaned_aar_file],
        progress_message = "Preparing intermediate data binding aar %s" % cleaned_aar_file.basename,
        command = """
        TEMP="$$(mktemp -d)"
        unzip -q -o {source_aar} -d $$TEMP/
        mkdir $$TEMP/data-binding/
        mkdir $$TEMP/data-binding-base-class-log/

        # Package all necessary DB files
        cp {setter_store_files} $$TEMP/data-binding/.
        cp {br_files} $$TEMP/data-binding/.
        cp {binding_classes} $$TEMP/data-binding-base-class-log/.

        # Delete extra classes
        zip -q -d $$TEMP/classes.jar "*/BR.class"
        zip -q -d $$TEMP/classes.jar "*/DataBindingInfo.class"
        zip -q -d $$TEMP/classes.jar "*/DataBindingComponent.class"

        # Package
        aar=$(pwd)/{output}
        cd $$TEMP; zip -q -r output.aar .
        cp output.aar $aar
        """.format(
            source_aar = source_aar.path,
            setter_store_files = " ".join([(setter_store.path) for setter_store in setter_store_files]),
            br_files = " ".join([(br_file.path) for br_file in br_files]),
            binding_classes = " ".join([(binding_classes.path) for binding_classes in binding_classes_files]),
            output = cleaned_aar_file.path,
        ),
    )

    ctx.actions.run_shell(
        inputs = [cleaned_kotlin_jar, cleaned_aar_file],
        outputs = [output_aar],
        progress_message = "Packaging data binding aar %s" % output_aar.basename,
        command = """
            TEMP="$$(mktemp -d)"
            CURR=$(pwd)
            aar=$(pwd)/{output}
            unzip -q -o {cleaned_aar} -d $$TEMP/
            mkdir $$TEMP/classes

            # Unzip Kotlin classes
            unzip -q -o {cleaned_kotlin_jar} -d $$TEMP/classes
            find $$TEMP/classes/. -path "*/META-INF/*" -delete

            # Unzip Databinding classes
            unzip -q -o $$TEMP/classes.jar -d $$TEMP/classes
            find $$TEMP/classes/. -type d -empty -delete
            rm $$TEMP/classes.jar

            # Package merged.jar
            cd $$TEMP/classes; zip -q -r merged.jar .
            cp merged.jar $CURR/$$TEMP/classes.jar
            rm -rf $CURR/$$TEMP/classes/

            cd $CURR/$$TEMP; zip -q -r output.aar .
            cp output.aar $aar
            """.format(
            cleaned_aar = cleaned_aar_file.path,
            cleaned_kotlin_jar = cleaned_kotlin_jar.path,
            output = output_aar.path,
        ),
    )

def _databinding_aar_impl(ctx):
    """
    A custom rule implementation to overcome couple of limitations in Databinding's Kotlin support and
    AAR file packaging. Namely it solves the following problems

    * AAR file generated by Bazel cannot be used by Gradle/Jetifier since it does not package all DB info
    * AAR file does not contain Kotlin compiled classes since android_library does not include transitive

    How it works:
    By directly accessing android_library's DataBindingV2Info, the rule extracts the relevant files
    and prepares them for packaging.

    By using the provided Kotlin jar, it merges all Kotlin classes into the final AAR

    It also cleans up couple of redundant databinding classes which must not be packaged into final AAR.
    """
    dep = ctx.attr.android_library
    android_lib_name = dep.label.name
    custom_package = dep.android.java_package
    java_info = ctx.attr.kotlin_library[JavaInfo]

    data_binding_info = dep[DataBindingV2Info]

    # Register action to copy setter stores
    setter_store_files = []
    if len(data_binding_info.setter_stores.to_list()) > 0:
        setter_store_input_file = data_binding_info.setter_stores.to_list()[0]
        setter_store_output_file = ctx.actions.declare_file(_DATABINDING + "/" + setter_store_input_file.basename)
        copy_file_action(
            ctx,
            setter_store_input_file,
            setter_store_output_file,
            "Setter stores",
        )
        setter_store_files.append(setter_store_output_file)

    # Register action to copy BR files
    br_files = []
    for br_input_file in data_binding_info.transitive_br_files.to_list():
        if (br_input_file.basename.find(".bin") != -1):
            br_output_file = ctx.actions.declare_file(_BR + "/" + br_input_file.basename)
            copy_file_action(
                ctx,
                br_input_file,
                br_output_file,
                "BR Files",
            )
            br_files.append(br_output_file)

    # Register action to copy binding_classes.json
    binding_classes_files = []
    if len(data_binding_info.class_infos.to_list()) > 0:
        class_info_zip_file = data_binding_info.class_infos.to_list()[0]
        binding_classes_json_file = ctx.actions.declare_file(custom_package + "-binding_classes.json")
        extract_binding_classes(ctx, class_info_zip_file, binding_classes_json_file)
        binding_classes_files.append(binding_classes_json_file)

    # Create temp output aar
    temp_aar_file = ctx.actions.declare_file(android_lib_name + "-temp.aar")
    copy_file_action(ctx, dep.android.aar, temp_aar_file)

    # Cleanup the Kotlin jar that was compiled in the first stage. This is written as separate action
    # as opposed to merging with _package_aar so that this could be parallelized before final packaging
    # action
    cleaned_kotlin_jar = ctx.actions.declare_file(android_lib_name + "-databinding-kotlin.jar")
    _clean_stubs_from_kotlin_jar(
        ctx,
        custom_package,
        java_info.runtime_output_jars[0],
        cleaned_kotlin_jar,
    )

    # Final action that packages all databinding generated file and Kotlin classes into an aar_file
    _package_aar(
        ctx,
        android_lib_name,
        setter_store_files,
        br_files,
        binding_classes_files,
        cleaned_kotlin_jar,
        temp_aar_file,
        ctx.outputs.aar,
    )

    return [DefaultInfo(
        files = depset([ctx.outputs.aar]),
    ), AndroidLibraryAarInfo(
        aar = ctx.outputs.aar,
        manifest = ctx.outputs.aar,
        aars_from_deps = [],
        defines_local_resources = True,
    ), java_info]

databinding_aar = rule(
    implementation = _databinding_aar_impl,
    attrs = {
        "android_library": attr.label(),
        "kotlin_library": attr.label(),
        # These exist only to satisfy the maven_publish aspect
        # requirements for aggregating transitive deps
        "deps": attr.label_list(),
        "exports": attr.label_list(),
    },
    outputs = {"aar": "%{name}.aar"},
    provides = [AndroidLibraryAarInfo, JavaInfo],
)
