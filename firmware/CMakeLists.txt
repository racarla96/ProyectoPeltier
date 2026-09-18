cmake_minimum_required(VERSION 3.13)

# Requiere PICO_SDK_PATH apuntando a una copia de pico-sdk
include($ENV{PICO_SDK_PATH}/pico_sdk_init.cmake)

project(peltier_virtual_plant C CXX ASM)

set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)

pico_sdk_init()

add_executable(peltier_virtual_plant
    main.c
)

target_link_libraries(peltier_virtual_plant
    pico_stdlib
)

# USB CDC habilitado, UART deshabilitado (toda la comunicacion es por USB)
pico_enable_stdio_usb(peltier_virtual_plant 1)
pico_enable_stdio_uart(peltier_virtual_plant 0)

pico_add_extra_outputs(peltier_virtual_plant)
