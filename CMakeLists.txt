cmake_minimum_required(VERSION 3.12)

project(n2os_smb_client)

# No direct OpenSSL dependency currently. Leave option for future use.
option(USE_OPENSSL "Enable OpenSSL support" OFF)
if(USE_OPENSSL)
    set(OPENSSL_USE_STATIC_LIBS TRUE)
    find_package(OpenSSL REQUIRED)
endif()

option(ENABLE_STATIC_LINKING "Link n2os_smb_client statically" OFF)

set(COMMON_COMPILE_OPTIONS "-O2" "-fPIC" "-fstack-protector" "-D_FORTIFY_SOURCE=2")
if(NOT ENABLE_STATIC_LINKING)
    list(APPEND COMMON_COMPILE_OPTIONS "-fPIE")
endif()
add_compile_options(${COMMON_COMPILE_OPTIONS})

if(ENABLE_STATIC_LINKING)
    if(APPLE)
        message(FATAL_ERROR "ENABLE_STATIC_LINKING is not supported on macOS.")
    endif()
    add_link_options("-static" "-static-libgcc")
else()
    if(NOT APPLE)
        add_link_options("-pie" "-Wl,-z,relro,-z,now")
    endif()
endif()

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(BUILD_SHARED_LIBS OFF CACHE BOOL "Disable shared libs")

if(CMAKE_CROSSCOMPILING)
    add_compile_definitions(HAVE_ARC4RANDOM=0 HAVE_ARC4RANDOM_BUF=0)
endif()

## LIB SMB2
if (NOT "${CMAKE_SYSTEM}" MATCHES "Linux" AND NOT APPLE)
    # FreeBSD specific fixes
    include_directories(${CMAKE_CURRENT_SOURCE_DIR}/include)
    add_definitions(-include freebsd_fix.h)
    add_compile_options("-Wno-macro-redefined")
endif()

set(LIBSMB2_DIR "${PROJECT_SOURCE_DIR}/deps/libsmb2")
message(STATUS "Lib smb2: ${LIBSMB2_DIR}")

if(NOT DEFINED KRB_IMPL)
    message(FATAL_ERROR "KRB_IMPL must be defined (MIT, HEIMDAL, or NONE).")
endif()

string(TOUPPER "${KRB_IMPL}" KRB_IMPL_UPPER)
set(ENABLE_KERBEROS TRUE)
if(KRB_IMPL_UPPER STREQUAL "NONE")
    set(ENABLE_KERBEROS FALSE)
    message(STATUS "Kerberos support disabled (KRB_IMPL=NONE)")
endif()

if(ENABLE_KERBEROS)
    include(${CMAKE_CURRENT_LIST_DIR}/FindKrb5.cmake)
    include(${CMAKE_CURRENT_LIST_DIR}/FindGssApi.cmake)

    if(NOT LibKrb5_FOUND)
        message(FATAL_ERROR "Kerberos libraries not found. Please install krb5 development packages.")
    endif()

    if(NOT GSSAPI_FOUND)
        message(FATAL_ERROR "GSSAPI libraries not found. Please install GSSAPI development packages.")
    endif()

    message(STATUS "LibKrb5_LIBRARY: ${LibKrb5_LIBRARY}")
    message(STATUS "LibKrb5_INCLUDE_DIR: ${LibKrb5_INCLUDE_DIR}")
    message(STATUS "LibKrb5_IMPL: ${LibKrb5_IMPL}")

    message(STATUS "GSSAPI_LIBRARY: ${GSSAPI_LIBRARY}")
    message(STATUS "GSSAPI_INCLUDE_DIR: ${GSSAPI_INCLUDE_DIR}")
    message(STATUS "KRB_IMPL: ${KRB_IMPL}")

    include_directories(BEFORE SYSTEM ${GSSAPI_INCLUDE_DIR} ${LibKrb5_INCLUDE_DIR})

    # force compile with krb5, library removes the support if krb5 is not found
    add_definitions(-DHAVE_LIBKRB5)
else()
    message(STATUS "Skipping Kerberos/GSSAPI discovery.")
endif()

# Propagate Kerberos toggles down to libsmb2
if(ENABLE_KERBEROS)
    set(ENABLE_LIBKRB5 ON CACHE BOOL "Enable libkrb5 in libsmb2" FORCE)
    set(ENABLE_GSSAPI ON CACHE BOOL "Enable GSSAPI in libsmb2" FORCE)
else()
    set(ENABLE_LIBKRB5 OFF CACHE BOOL "Enable libkrb5 in libsmb2" FORCE)
    set(ENABLE_GSSAPI OFF CACHE BOOL "Enable GSSAPI in libsmb2" FORCE)
endif()

add_subdirectory(${LIBSMB2_DIR})
include_directories(${LIBSMB2_DIR}/include/smb2)
include_directories(${LIBSMB2_DIR}/include)


## LIB JSON-C
set(LIBJSONC_DIR "${PROJECT_SOURCE_DIR}/deps/json-c")
if(NOT EXISTS "${LIBJSONC_DIR}/CMakeLists.txt")
    message(FATAL_ERROR "json-c submodule not found. Run `git submodule update --init --recursive`.")
endif()
message(STATUS "Lib json-c: ${LIBJSONC_DIR}")
add_subdirectory(${LIBJSONC_DIR})
include_directories(${LIBJSONC_DIR})
include_directories(${CMAKE_BINARY_DIR}/deps/json-c)

add_executable(n2os_smb_client n2os-smb-client.c)

set(N2OS_CLIENT_LIBS smb2 json-c)

if(ENABLE_KERBEROS)
    list(APPEND N2OS_CLIENT_LIBS ${GSSAPI_LIBRARY} ${LibKrb5_LIBRARY})
endif()

target_link_libraries(n2os_smb_client ${N2OS_CLIENT_LIBS})
