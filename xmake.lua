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

before_build(function()
    import("core.project.project")
    
    local submodules = {
        "modules/midend",
        "modules/riscv64"
    }
    
    local needs_init = false
    for _, submodule in ipairs(submodules) do
        local submodule_path = path.join(os.projectdir(), submodule)
        if not os.isdir(submodule_path) or #os.dirs(path.join(submodule_path, "*")) == 0 then
            needs_init = true
            break
        end
    end
    
    if needs_init then
        cprint("${color.info}Initializing git submodules...")
        local ok = os.exec("git submodule update --init --recursive")
        if ok ~= 0 then
            error("Failed to initialize git submodules")
        end
    end
end)

includes("modules/midend/xmake.lua")
includes("modules/riscv64/xmake.lua")

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
        
        local submodules = {
            {path = "modules/midend", branch = "main"},
            {path = "modules/riscv64", branch = "master"}
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
