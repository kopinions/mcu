cmake_minimum_required(VERSION 3.1)
project(mcu C CXX)

set(CMAKE_MODULE_PATH "${CMAKE_MODULE_PATH}" "${CMAKE_CURRENT_LIST_DIR}/cmake")

option(LOGIC_TESTS "Enable/disable tests" ON)
option(LOGIC_RTL "Enable/disable RTL build" ON)
option(LOGIC_WARNINGS_INTO_ERRORS "Enable/disable warnings as errors" OFF)

include(AddLogic)

if (LOGIC_RTL)
  add_subdirectory(rtl)

  if (LOGIC_TESTS)
    include(CTest)
    add_subdirectory(tests)
  endif()
endif()
