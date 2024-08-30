package("dobby")
    set_description("a lightweight, multi-platform, multi-architecture hook framework.")
    set_license("Apache-2.0")

    add_urls("https://github.com/Redbeanw44602/Dobby/archive/refs/tags/$(version).tar.gz",
             "https://github.com/Redbeanw44602/Dobby.git")

    add_versions("v0.1.0", "94047e1243f22cc0f14de22279c0bb51558935e1d75674805e61970814369ef0")
    add_versions("v0.1.1", "3f9dac8e0b252ab663947b5ca35475bb1550d3271e52c2d088ca2898e7be4ed2")
    add_versions("v0.1.2", "49fd477f2e8fd65c01859a7596659d8057f0933908f902bad51c07323863ae8e")

    -- build
    add_configs("debug", {description = "Enable debug logging.", default = false, type = "boolean"})
    add_configs("example", {description = "Enable example build.", default = false, type = "boolean"})
    add_configs("test", {description = "Enable test build.", default = false, type = "boolean"})

    -- plugins
    add_configs("symbol_resolver", {description = "Enable symbol resolver plugin.", default = true, type = "boolean"})
    add_configs("import_table_replacer", {description = "Enable import table replacer plugin.", default = false, type = "boolean"})
    add_configs("android_bionic_linker_utils", {description = "Enable android bionic linker utils.", default = false, type = "boolean"})

    -- features
    add_configs("near_branch", {description = "Enable near branch trampoline.", default = true, type = "boolean"})
    add_configs("full_floating_point_register_pack", {description = "Enables saving and packing of all floating-point registers.", default = false, type = "boolean"})

    add_deps("cmake")
    on_install("linux", "macosx", function (package)
        function xmake_option(option)
            return package:config(option) and "ON" or "OFF"
        end
        local configs = {
            "-DDOBBY_DEBUG="                     .. xmake_option("debug"),
            "-DDOBBY_BUILD_EXAMPLE="             .. xmake_option("example"),
            "-DDOBBY_BUILD_TEST="                .. xmake_option("test"),
            "-DPlugin.SymbolResolver="           .. xmake_option("symbol_resolver"),
            "-DPlugin.ImportTableReplace="       .. xmake_option("import_table_replacer"),
            "-DPlugin.Android.BionicLinkerUtil=" .. xmake_option("android_bionic_linker_utils"),
            "-DNearBranch="                      .. xmake_option("near_branch"),
            "-DFullFloatingPointRegisterPack="   .. xmake_option("full_floating_point_register_pack")
        }
        table.insert(configs, "-DCMAKE_BUILD_TYPE=" .. (package:debug() and "Debug" or "Release"))
        table.insert(configs, "-DCMAKE_SYSTEM_PROCESSOR=" .. package:targetarch())
        import("package.tools.cmake").install(package, configs, {buildir = "build"})
        os.cp("include", package:installdir())
        os.trycp("build/**.a", package:installdir("lib"))
        os.trycp("build/**.so", package:installdir("lib"))
    end)

    on_test(function (package)
        assert(package:check_cxxsnippets({test = [[
            void test() {
                DobbyGetVersion();
            }
        ]]}, {configs = {languages = "c++11"}, includes = "dobby.h"}))
    end)
