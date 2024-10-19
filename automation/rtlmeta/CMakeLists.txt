cmake_minimum_required(VERSION 3.26)
project(rtlmeta C CXX)

SET(CMAKE_CXX_FLAGS  "${CMAKE_CXX_FLAGS} -std=c++23 -g")
SET(CMAKE_C_FLAGS  "${CMAKE_C_FLAGS} -g")
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
#
# parser GUI
file(GLOB_RECURSE MYWAVE_SOURCES CONFIGURE_DEPENDS "${CMAKE_CURRENT_LIST_DIR}/src/*.cpp")

add_executable(rtlmeta)
target_sources(rtlmeta PRIVATE ${PROJECT_SOURCES} ${MYWAVE_SOURCES})
target_include_directories(rtlmeta
        PRIVATE
        /usr/share/yosys/include/
        src)
target_link_libraries(rtlmeta PRIVATE /usr/lib/yosys/libyosys.so ${libs})
