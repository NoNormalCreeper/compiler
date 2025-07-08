add_executable(compiler main.cpp)

target_link_libraries(compiler PRIVATE midend)

target_include_directories(compiler PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
)