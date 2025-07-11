add_requires("gtest 1.14.0", {configs = {shared = false}})

target("compiler_tests")
    set_kind("binary")
    set_languages("c++17")
    set_default(false)
    
    add_packages("gtest")
    
    add_files("*.cpp")
    
    add_deps("compiler", "riscv64", "midend")
    
    -- add_includedirs("../include")
    
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
    
    add_ldflags("-pthread")