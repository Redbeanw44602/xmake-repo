package('llvm-prebuilt')
    set_kind('library')
    set_homepage('https://llvm.org/')
    set_description('The LLVM Compiler Infrastructure.')

    add_configs('shared', {description = 'Build shared library.', default = false, type = 'boolean', readonly = true})
    add_configs('linux_dist', {description = 'Target linux distribution (for linux platform only)', default = 'ubuntu-24.04', type = 'string'})

    on_source(function (package)
        local gh_repo = 'awakecoding/llvm-prebuilt'
        local ah_suffix = '.tar.xz'
        local os_win = 'windows'
        local os_macosx = 'macos'
        local os_linux = package:config('linux_dist')
        local ar_amd64 = 'x86_64'
        local ar_arm64 = 'aarch64'

        import('core.base.json')
        import('net.http')
        function get(url)
            tmp_file = os.tmpfile()
            http.download(url, tmp_file)
            return io.readfile(tmp_file)
        end

        local latest_release = json.decode(get(('https://api.github.com/repos/%s/releases/latest'):format(gh_repo)))
        local pkgs = {}
        local chksums = {}
        for _, asset in pairs(latest_release['assets']) do
            local name = asset['name']
            local download_url = asset['browser_download_url']
            if name == 'checksums' then
                local checksum_raw = get(download_url)
                for _, line in pairs(checksum_raw:split('\n')) do
                    local kv = line:split('  ')
                    chksums[kv[2]] = kv[1]:lower()
                end
            end
            if name:startswith('clang+llvm') then
                local triple_raw = name:sub(('clang+llvm'):len() + 2):sub(0, -(ah_suffix):len() - 1) -- {version}-{arch}-{os}
                local triple = triple_raw:split('-')
                table.insert(pkgs, {
                    name = name,
                    version = triple[1],
                    arch = triple[2],
                    os = table.concat(table.slice(triple, 3), '-')
                })
            end
        end

        local url_template = 'https://github.com/%s/releases/download/%s/clang+llvm-$(version)-%s-%s%s'
        local tag = latest_release['tag_name']
        if package:is_plat('linux') and package:is_arch('x86_64') then
            package:set('urls', url_template:format(gh_repo, tag, ar_amd64, os_linux, ah_suffix))
        end
        if package:is_plat('linux') and package:is_arch('arm64') then
            package:set('urls', url_template:format(gh_repo, tag, ar_arm64, os_linux, ah_suffix))
        end
        if package:is_plat('macosx') and package:is_arch('x86_64') then
            package:set('urls', url_template:format(gh_repo, tag, ar_amd64, os_macosx, ah_suffix))
        end
        if package:is_plat('macosx') and package:is_arch('arm64') then
            package:set('urls', url_template:format(gh_repo, tag, ar_arm64, os_macosx, ah_suffix))
        end
        if package:is_plat('windows') and package:is_arch('x64') then
            package:set('urls', url_template:format(gh_repo, tag, ar_amd64, os_win, ah_suffix))
        end
        if package:is_plat('windows') and package:is_arch('arm64') then
            package:set('urls', url_template:format(gh_repo, tag, ar_arm64, os_win, ah_suffix))
        end

        for _, pkg in pairs(pkgs) do
            if pkg['os'] == os_win and package:is_plat('windows') then
                package:add('versions', pkg['version'], chksums[pkg['name']])
            end
            if pkg['os'] == os_macosx and package:is_plat('macosx') then
                package:add('versions', pkg['version'], chksums[pkg['name']])
            end
            if pkg['os'] == os_linux and package:is_plat('linux') then
                package:add('versions', pkg['version'], chksums[pkg['name']])
            end
        end
    end)

    on_load(function (package)
        package:add('components', 'base')
        package:add('components', 'clang', {deps = 'base'})
        package:add('deps', 'zlib')
    end)

    on_install('linux', 'macosx', 'windows', function (package)
        os.rmdir('bin')
        os.rmdir('share')
        os.cp('*', package:installdir())
    end)

    on_component('clang', 'components.clang')
    on_component('base',  'components.base')

    on_test(function (package)
        assert(package:check_cxxsnippets({test = [[
            #include <clang/Frontend/CompilerInstance.h>
            int main(int argc, char** argv) {
                clang::CompilerInstance instance;
                return 0;
            }
        ]]}, {configs = {languages = 'c++17'}}))
    end)
