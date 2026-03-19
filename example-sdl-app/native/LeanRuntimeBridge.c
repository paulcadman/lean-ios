#include "LeanRuntimeBridge.h"

void lean_initialize_runtime_module(void);
void lean_initialize_thread(void);

bool lean_runtime_initialize_modules(const lean_module_initializer_fn *modules, size_t module_count) {
    static bool runtime_initialized = false;

    if (!runtime_initialized) {
        lean_initialize_runtime_module();
        lean_initialize_thread();
        runtime_initialized = true;
    }

    for (size_t i = 0; i < module_count; ++i) {
        lean_object *result = modules[i](1);
        if (lean_io_result_is_error(result)) {
            lean_dec_ref(result);
            return false;
        }
        lean_dec_ref(result);
    }

    return true;
}
