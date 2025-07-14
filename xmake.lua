set_project("Compiler")
set_version("0.1.0")

set_xmakever("2.8.0")

set_languages("c++17")
set_warnings("all")

add_cxxflags("-Wall", "-Wextra")

if is_mode("debug") then
    add_cxxflags("-g", "-O0")
    set_symbols("debug")
    set_optimize("none")
elseif is_mode("release") then
    add_cxxflags("-O3", "-DNDEBUG")
    set_symbols("hidden")
    set_optimize("fastest")
end

set_policy("build.ccache", true)
set_policy("build.warning", true)

add_rules("plugin.compile_commands.autoupdate", {outputdir = "."})

includes("modules/midend/xmake.lua")
includes("modules/riscv64/xmake.lua")
includes("modules/frontend/xmake.lua")

target("compiler")
    set_kind("binary")
    set_targetdir("$(builddir)")
    
    add_files("src/*.cpp")
    -- add_includedirs("include")
    
    add_deps("riscv64", "midend")
    add_rpathdirs("@loader_path", "@loader_path/lib")

if os.isdir(path.join(os.scriptdir(), "tests")) then
    includes("tests/xmake.lua")
end

task("update-submodules")
    on_run(function()
        import("core.project.project")
        
        local projectdir = project.directory()
        os.cd(projectdir)
        
        cprint("${bright blue}Updating submodules to latest commits...")

        os.exec("git submodule update --init --recursive")
        
        local submodules = {
            {path = "modules/midend", branch = "main"},
            {path = "modules/riscv64", branch = "master"},
            {path = "modules/frontend", branch = "main"}
        }
        
        for _, submodule in ipairs(submodules) do
            cprint("${bright yellow}Updating %s...", submodule.path)
            os.cd(path.join(projectdir, submodule.path))
            os.exec("git checkout %s", submodule.branch)
            os.exec("git pull origin %s", submodule.branch)
        end
        
        os.cd(projectdir)
        cprint("${color.success}All submodules updated successfully!")
    end)
    
    set_menu {
        usage = "xmake update-submodules",
        description = "Update all submodules to their latest commits"
    }

task("test")
    on_run(function()
        import("core.base.task")
        task.run("build", {targets = {"compiler_tests"}})
        os.exec("xmake run compiler_tests")
    end)
    
    set_menu {
        usage = "xmake test",
        description = "Run all tests"
    }

task("test-all")
    on_run(function()
        import("core.base.task")
        cprint("${color.info}Running compiler tests...")
        task.run("build", {targets = {"compiler_tests"}})
        os.exec("xmake run compiler_tests")
        
        cprint("${color.info}Running midend tests...")
        task.run("build", {targets = {"midend_tests"}})
        os.exec("xmake run midend_tests")
    end)
    
    set_menu {
        usage = "xmake test-all",
        description = "Run all tests including submodule tests"
    }


task("format")
    set_menu {
        usage = "xmake format",
        description = "Check code formatting with clang-format",
        options = {
            {'c', "check", "k", false, "Run clang-format in dry-run mode to check formatting without making changes."},
        }
    }
    on_run(function ()
        import("lib.detect.find_tool")
        import("core.base.option")
        local clang_format = find_tool("clang-format-15") or find_tool("clang-format")
        if not clang_format then
            raise("clang-format-15 or clang-format is required for formatting")
        end
        
        local cmd = "find . -name '*.cpp' -o -name '*.h' | grep -v build | grep -v googletest | grep -v modules | grep -v _deps | xargs " .. clang_format.program
        if option.get("check") then
            cmd = cmd .. " --dry-run --Werror"
        else
            cmd = cmd .. " -i"
        end
        local ok, outdata, errdata = os.iorunv("sh", {"-c", cmd})
        
        if not ok then
            cprint("${red}Code formatting check failed:")
            if errdata and #errdata > 0 then
                print(errdata)
            end
            os.exit(1)
        else
            cprint("${green}All files are properly formatted!")
        end
    end)