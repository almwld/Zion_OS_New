cmake_minimum_required(VERSION 3.22.1)
project(zionpty LANGUAGES CXX)

add_library(zionpty SHARED zion_pty.cpp)

target_compile_features(zionpty PRIVATE cxx_std_17)

target_link_libraries(zionpty android log)
