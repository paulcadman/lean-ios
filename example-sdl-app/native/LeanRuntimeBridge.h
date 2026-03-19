#ifndef LEAN_RUNTIME_BRIDGE_H
#define LEAN_RUNTIME_BRIDGE_H

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#include <lean/lean.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef lean_object *(*lean_module_initializer_fn)(uint8_t builtin);

bool lean_runtime_initialize_modules(const lean_module_initializer_fn *modules, size_t module_count);

#ifdef __cplusplus
}
#endif

#endif
