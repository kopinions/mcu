set(DESIGN_PATH ${CMAKE_CURRENT_LIST_DIR}/design)
add_custom_command(
    OUTPUT _vmake
    COMMAND ${CMAKE_COMMAND} -E env DESIGN_PATH=${CMAKE_CURRENT_LIST_DIR}/design iverilog -c ${CMAKE_CURRENT_LIST_DIR}/design/mcu_rtl.vc
    COMMENT "Compiling Verilog files"
    )


  add_custom_target(compile DEPENDS _vmake)
