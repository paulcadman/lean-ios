#ifndef LEAN_SDL_BINDINGS_H
#define LEAN_SDL_BINDINGS_H

#include <lean/lean.h>

lean_obj_res lean_sdl_init_video(void);
lean_obj_res lean_sdl_setup_window_and_renderer(b_lean_obj_arg title, uint32_t width, uint32_t height);
lean_obj_res lean_sdl_get_render_output_width(void);
lean_obj_res lean_sdl_get_render_output_height(void);
lean_obj_res lean_sdl_set_render_draw_color(uint32_t r, uint32_t g, uint32_t b, uint32_t a);
lean_obj_res lean_sdl_render_clear(void);
lean_obj_res lean_sdl_render_fill_rect(uint32_t x, uint32_t y, uint32_t w, uint32_t h);
lean_obj_res lean_sdl_render_present(void);
lean_obj_res lean_sdl_shutdown(void);

#endif
