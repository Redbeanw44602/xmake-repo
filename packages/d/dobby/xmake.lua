package("dobby")
    set_description("a lightweight, multi-platform, multi-architecture hook framework.")
    set_license("Apache-2.0")

    add_urls("https://github.com/LiteLDev/Dobby/archive/refs/tags/$(version).tar.gz",
             "https://github.com/LiteLDev/Dobby.git")

    add_versions("v0.1.0", "37181f1bcffb120d1dcacbc33d0de2156bdd235290a78c62691e44c5d2bcb76c")

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
        import("package.tools.cmake").install(package, configs)
    end)

    on_test(function (package)
        assert(package:check_cxxsnippets({test = [[
            void test () {
                DobbyGetVersion();
            }
        ]]}, {configs = {languages = "c++17"}, includes = "dobby.h"}))
    end)
