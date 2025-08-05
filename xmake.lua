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
    
    add_deps("riscv64", "midend", "frontend")
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

task("test")
    set_menu {
        usage = "xmake test",
        description = "Run tests",
        options = {
            {'t', "target", "v", nil, "测试目标（.sy 文件或测试用例目录）"},
            {'o', "optimization", "kv", "0", "优化级别（0 或 1）"},
            {'p', "pipeline", "kv", nil, "优化 Pipeline"},
            {'s', "hidden", "k", nil, "关闭标准输出"}
        }
    }
    on_run(function ()
        import("core.project.project")
        import("core.base.task")
        import("lib.detect.find_tool")
        import("core.base.option")
        import("devel.git")
        local python3 = find_tool("python3")
        if not python3 then
            raise("Python3 is required to run tests")
        end
        task.run("build", {target = "compiler"})
        local target = project.target("compiler")
        local target_executable = path.absolute(target:targetfile())
        local test_script_dir = path.join(target:targetdir(), "test_script")
        if not os.isdir(test_script_dir) then
            cprint("${blue}test_script not found, cloning from repository...")
            git.clone("https://github.com/BUPT-a-out/test-script.git", {outputdir = test_script_dir, branch = "master"})
        end
        local test_script = path.join(test_script_dir, "test.py")
        local test_target = option.get("target")
        if test_target == nil then
            raise("Please specify a test target")
        end
        local level = option.get("optimization") or "0"
        local pipeline = option.get("pipeline")
        if pipeline ~= nil then
            pipeline = " -p " .. pipeline
        else
            pipeline = ""
        end
        local hidden = option.get("hidden")
        if hidden then
            hidden = " --no-stdout "
        else
            hidden = ""
        end
        local command = python3.program .. " " .. test_script .. " run " .. hidden .. path.join(os.workingdir(), test_target) .. " -- " .. target_executable .. " -S -O" .. level .. pipeline
        print("Running test command: " .. command)
        os.exec(command)
    end)

task("debug")
    set_menu {
        usage = "xmake debug",
        description = "Debug a test target",
        options = {
            {'t', "target", "v", nil, "测试目标（.sy 文件或测试用例目录）"},
            {'o', "optimization", "kv", "0", "优化级别（0 或 1）"},
            {'p', "pipeline", "kv", nil, "优化 Pipeline"}
        }
    }
    on_run(function ()
        import("core.project.project")
        import("core.base.task")
        import("lib.detect.find_tool")
        import("core.base.option")
        import("devel.git")
        local python3 = find_tool("python3")
        if not python3 then
            raise("Python3 is required to run tests")
        end
        task.run("build", {target = "compiler"})
        local target = project.target("compiler")
        local target_executable = path.absolute(target:targetfile())
        local test_script_dir = path.join(target:targetdir(), "test_script")
        if not os.isdir(test_script_dir) then
            cprint("${blue}test_script not found, cloning from repository...")
            git.clone("https://github.com/BUPT-a-out/test-script.git", {outputdir = test_script_dir, branch = "master"})
        end
        local test_script = path.join(test_script_dir, "test.py")
        local test_target = option.get("target")
        if test_target == nil then
            raise("Please specify a test target")
        end
        local level = option.get("optimization") or "0"
        local pipeline = option.get("pipeline")
        if pipeline ~= nil then
            pipeline = " -p " .. pipeline
        else
            pipeline = ""
        end
        local command = python3.program .. " " .. test_script .. " debug " .. path.join(os.workingdir(), test_target) .. " -- " .. target_executable .. " -S -O" .. level .. pipeline
        print("Running test command: " .. command)
        os.exec(command)
    end)


task("gen")
    set_menu {
        usage = "xmake gen",
        description = "Generate assembly code for a test target",
        options = {
            {'t', "target", "v", nil, "测试目标（.sy 文件）"},
            {'o', "optimization", "kv", "0", "优化级别（0 或 1）"},
            {'s', "save", "kv", nil, "保存汇编结果到指定文件"},
            {'p', "pipeline", "kv", nil, "优化 Pipeline"},
            {'i', "ir", "k", nil, "生成 IR 输出"}
        }
    }
    on_run(function ()
        import("core.project.project")
        import("core.base.task")
        import("lib.detect.find_tool")
        import("core.base.option")
        import("devel.git")
        task.run("build", {target = "compiler"})
        local target = project.target("compiler")
        local target_executable = path.absolute(target:targetfile())
        local test_target = option.get("target")
        if test_target == nil then
            raise("Please specify a test target")
        end
        local level = option.get("optimization") or "0"
        local pipeline = option.get("pipeline")
        if pipeline ~= nil then
            pipeline = " -p " .. pipeline
        else
            pipeline = ""
        end
        local save_file = option.get("save")
        if save_file then
            save_file = " -o " .. save_file
        else
            save_file = ""
        end
        local output = " -S "
        if option.get("ir") then
            output = " --emit-ir "
        end

        local command = target_executable .. " " .. path.join(os.workingdir(), test_target) .. output .. "-O" .. level .. pipeline .. save_file
        print("Running test command: " .. command)
        os.exec(command, {stdin=stdin})
    end)

task("clang")
    set_menu {
        usage = "xmake clang",
        description = "Run test with clang",
        options = {
            {'t', "target", "v", nil, "测试目标（.sy 文件或测试用例目录）"}
        }
    }
    on_run(function ()
        import("core.project.project")
        import("core.base.task")
        import("lib.detect.find_tool")
        import("core.base.option")
        import("devel.git")
        local python3 = find_tool("python3")
        if not python3 then
            raise("Python3 is required to run tests")
        end
        local target = project.target("compiler")
        local test_script_dir = path.join(target:targetdir(), "test_script")
        if not os.isdir(test_script_dir) then
            cprint("${blue}test_script not found, cloning from repository...")
            git.clone("https://github.com/BUPT-a-out/test-script.git", {outputdir = test_script_dir, branch = "master"})
        end
        local test_script = path.join(test_script_dir, "test.py")
        local test_target = option.get("target")
        if test_target == nil then
            raise("Please specify a test target")
        end
        local command = python3.program .. " " .. path.join(os.workingdir(), test_target) .. " clang " .. test_target
        print("Running test command: " .. command)
        os.exec(command)
    end)