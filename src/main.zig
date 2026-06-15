const std = @import("std");

const SDL = @import("./sdl.zig").SDL;
const editor = @import("./editor.zig");

pub fn main(_init: std.process.Init) !void {
    _ = _init; // autofix

    const WIDTH = 800;
    const HEIGHT = 600;

    if (!SDL.SDL_Init(SDL.SDL_INIT_VIDEO)) {
        std.debug.print("CANNOT INIT SDL: {s}\n", .{SDL.SDL_GetError()});
        return error.SDLInitFailed;
    }
    defer SDL.SDL_Quit();

    const window = SDL.SDL_CreateWindow("GooseQuill", WIDTH, HEIGHT, 0);
    if (window == null) {
        std.debug.print("CANNOT CREATE WINDOW\n", .{});
        return error.SDLCreateWindowFailed;
    }
    defer SDL.SDL_DestroyWindow(window);

    const renderer = SDL.SDL_CreateRenderer(window, null) orelse return error.SDLCReateRendererFailed;
    defer SDL.SDL_DestroyRenderer(renderer);

    const font_path = "main_font.ttf";

    if (!SDL.TTF_Init()) {
        std.debug.print("TTF_Init failed: {s}\n", .{SDL.SDL_GetError()});
        return error.TTFInitFailed;
    }
    defer SDL.TTF_Quit();

    const font = SDL.TTF_OpenFont(font_path, 22) orelse {
        std.debug.print("TTF_OpenFont failed: {s}\n", .{SDL.SDL_GetError()});
        return error.TTFOpenFontFailed;
    };
    defer SDL.TTF_CloseFont(font);

    var window_should_close: bool = false;

    while (!window_should_close) {
        var event: SDL.SDL_Event = undefined;
        while (SDL.SDL_PollEvent(&event)) {
            if (event.type == SDL.SDL_EVENT_QUIT) {
                window_should_close = true;
            }
        }

        _ = SDL.SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
        _ = SDL.SDL_RenderClear(renderer);

        editor.draw(renderer, font);

        _ = SDL.SDL_RenderPresent(renderer);
    }
}
