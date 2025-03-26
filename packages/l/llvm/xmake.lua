-- from: https://github.com/xmake-io/xmake-repo/blob/master/packages/l/llvm

--- 1. update to latest version.
--- 2. fix package kind.
--- 3. fix test.

package("llvm")
    set_kind("library")
    set_homepage("https://llvm.org/")
    set_description("The LLVM Compiler Infrastructure")
    add_configs("shared",            {description = "Build shared library.", default = false, type = "boolean", readonly = true})

    add_configs("all",               {description = "Enable all projects.", default = false, type = "boolean"})
    add_configs("bolt",              {description = "Enable bolt project.", default = false, type = "boolean"})
    add_configs("clang",             {description = "Enable clang project.", default = true, type = "boolean"})
    add_configs("clang-tools-extra", {description = "Enable extra clang tools project.", default = false, type = "boolean"})
    add_configs("libclc",            {description = "Enable libclc project.", default = false, type = "boolean"})
    add_configs("lld",               {description = "Enable lld project.", default = false, type = "boolean"})
    add_configs("lldb",              {description = "Enable lldb project.", default = false, type = "boolean"})
    add_configs("polly",             {description = "Enable polly project.", default = false, type = "boolean"})
    add_configs("pstl",              {description = "Enable pstl project.", default = false, type = "boolean"})
    add_configs("mlir",              {description = "Enable mlir project.", default = false, type = "boolean"})
    add_configs("flang",             {description = "Enable flang project.", default = false, type = "boolean"})
    add_configs("compiler-rt",       {description = "Enable compiler-rt project.", default = true, type = "boolean"})

    add_configs("libunwind",         {description = "Enable libunwind runtime.", default = true, type = "boolean"})
    add_configs("libc",              {description = "Enable libc runtime.", default = false, type = "boolean"})
    add_configs("libcxx",            {description = "Enable libcxx runtime.", default = true, type = "boolean"})
    add_configs("libcxxabi",         {description = "Enable libcxxabi runtime.", default = true, type = "boolean"})
    add_configs("openmp",            {description = "Enable openmp runtime.", default = false, type = "boolean"})

    set_urls("https://github.com/llvm/llvm-project/releases/download/llvmorg-$(version)/llvm-project-$(version).src.tar.xz")
    add_versions("11.1.0", "74d2529159fd118c3eac6f90107b5611bccc6f647fdea104024183e8d5e25831")
    add_versions("12.0.1", "129cb25cd13677aad951ce5c2deb0fe4afc1e9d98950f53b51bdcfb5a73afa0e")
    add_versions("13.0.1", "326335a830f2e32d06d0a36393b5455d17dc73e0bd1211065227ee014f92cbf8")
    add_versions("14.0.6", "8b3cfd7bc695bd6cea0f37f53f0981f34f87496e79e2529874fd03a2f9dd3a8a")
    add_versions("15.0.7", "8b5fcb24b4128cf04df1b0b9410ce8b1a729cb3c544e6da885d234280dedeac6")
    add_versions("16.0.6", "ce5e71081d17ce9e86d7cbcfa28c4b04b9300f8fb7e78422b1feb6bc52c3028e")
    add_versions("17.0.6", "58a8818c60e6627064f312dbf46c02d9949956558340938b71cf731ad8bc0813")
    add_versions("18.1.8", "0b58557a6d32ceee97c8d533a59b9212d87e0fc4d2833924eb6c611247db2f2a")
    add_versions("19.1.7", "82401fea7b79d0078043f7598b835284d6650a75b93e64b6f761ea7b63097501")

    on_load(function (package)
        if not package:is_plat("windows", "msys") then
            package:add("deps", "cmake")
            package:add("deps", "python 3.x", {kind = "binary", host = true})
            package:add("deps", "zlib", "libffi", {host = true})
        end
        if package:is_plat("linux") then
            package:add("deps", "binutils", {host = true}) -- needed for gold and strip
        end
        if package:is_plat("linux", "bsd") then
            if package:config("openmp") then
                package:add("deps", "libelf", {host = true})
            end
        end
        -- add components
        local components = {"mlir", "clang", "libunwind"}
        for _, name in ipairs(components) do
            if package:config(name) or package:config("all") then
                package:add("components", name, {deps = "base"})
            end
        end
        package:add("components", "base", {default = true})
    end)

    on_fetch("fetch")

    on_install("windows", "msys", function (package)
        os.cp("*", package:installdir())
    end)

    on_install("linux", "macosx|x86_64", "bsd", function (package)
        local projects = {
            "bolt",
            "clang",
            "clang-tools-extra",
            "libclc",
            "lld",
            "lldb",
            "openmp",
            "polly",
            "pstl",
            "mlir",
            "flang",
            "compiler-rt",
            "openmp"
        }
        local projects_enabled = {}
        if package:config("all") then
            table.insert(projects_enabled, "all")
        else
            for _, project in ipairs(projects) do
                if package:config(project) then
                    table.insert(projects_enabled, project)
                end
            end
        end
        local runtimes = {
            "libc",
            "libunwind",
            "libcxx",
            "libcxxabi"
        }
        local runtimes_enabled = {}
        for _, runtime in ipairs(runtimes) do
            if package:config(runtime) then
                table.insert(runtimes_enabled, runtime)
            end
        end
        local configs = {
            "-DCMAKE_BUILD_TYPE=Release",
            "-DLLVM_ENABLE_PROJECTS=" .. table.concat(projects_enabled, ";"),
            "-DLLVM_ENABLE_RUNTIMES=" .. table.concat(runtimes_enabled, ";"),
            "-DLLVM_POLLY_LINK_INTO_TOOLS=ON",
            "-DLLVM_BUILD_EXTERNAL_COMPILER_RT=ON",
            "-DLLVM_LINK_LLVM_DYLIB=ON",
            "-DLLVM_ENABLE_EH=ON",
            "-DLLVM_ENABLE_FFI=ON",
            "-DLLVM_ENABLE_RTTI=ON",
            "-DLLVM_INCLUDE_DOCS=OFF",
            "-DLLVM_INCLUDE_TESTS=OFF",
            "-DLLVM_INSTALL_UTILS=ON",
            "-DLLVM_ENABLE_Z3_SOLVER=OFF",
            "-DLLVM_OPTIMIZED_TABLEGEN=ON",
            "-DLLVM_TARGETS_TO_BUILD=all",
            "-DFFI_INCLUDE_DIR=" .. package:dep("libffi"):installdir("include"),
            "-DFFI_LIBRARY_DIR=" .. package:dep("libffi"):installdir("lib"),
            "-DLLDB_USE_SYSTEM_DEBUGSERVER=ON",
            "-DLLDB_ENABLE_PYTHON=OFF",
            "-DLLDB_ENABLE_LUA=OFF",
            "-DLLDB_ENABLE_LZMA=OFF",
            "-DLIBOMP_INSTALL_ALIASES=OFF"
        }
        table.insert(configs, "-DLLVM_CREATE_XCODE_TOOLCHAIN=" .. (package:is_plat("macosx") and "ON" or "OFF")) -- TODO
        table.insert(configs, "-DLLVM_BUILD_LLVM_C_DYLIB=" .. (package:is_plat("macosx") and "ON" or "OFF"))
        if package:has_tool("cxx", "clang", "clangxx") then
            table.insert(configs, "-DLLVM_ENABLE_LIBCXX=ON")
        else
            table.insert(configs, "-DLLVM_ENABLE_LIBCXX=OFF")
            table.insert(configs, "-DCLANG_DEFAULT_CXX_STDLIB=libstdc++")
            -- enable llvm gold plugin for LTO
            local binutils = package:dep("binutils")
            if binutils then
                table.insert(configs, "-DLLVM_BINUTILS_INCDIR=" .. binutils:installdir("include"))
            end
        end
        os.cd("llvm")
        import("package.tools.cmake").install(package, configs)
    end)

    on_component("mlir",      "components.mlir")
    on_component("clang",     "components.clang")
    on_component("libunwind", "components.libunwind")
    on_component("base",      "components.base")

    on_test(function (package)
        assert(package:check_cxxsnippets({test = [[
            #include <clang/Frontend/CompilerInstance.h>
            int main(int argc, char** argv) {
                clang::CompilerInstance instance;
                return 0;
            }
        ]]}, {configs = {languages = 'c++17'}}))
    end)
