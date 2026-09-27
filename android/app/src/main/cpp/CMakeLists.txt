cmake_minimum_required(VERSION 3.22.1)

add_library(zionpty SHARED zion_pty.c)

find_library(log-lib log)
target_link_libraries(zionpty ${log-lib})
