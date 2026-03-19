#include "LeanSDLModuleRegistration.h"

lean_object * initialize_ExampleSDL(uint8_t builtin);

const lean_module_initializer_fn lean_sdl_app_modules[] = {
    initialize_ExampleSDL,
};

const size_t lean_sdl_app_module_count =
    sizeof(lean_sdl_app_modules) / sizeof(lean_sdl_app_modules[0]);
