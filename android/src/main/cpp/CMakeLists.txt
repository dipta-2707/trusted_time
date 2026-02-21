cmake_minimum_required(VERSION 3.10.2)
project(uptime)

set(SHARED_SRC_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../../../../src")

add_library(
        uptime
        SHARED
        "${SHARED_SRC_DIR}/uptime.c"
)

target_include_directories(uptime PRIVATE "${SHARED_SRC_DIR}")
