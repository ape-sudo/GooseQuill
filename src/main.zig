const std = @import("std");

const SDL = @import("./sdl.zig").SDL;
const Editor = @import("./editor.zig").Editor;

pub fn main(init: std.process.Init) !void {
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

    if (!SDL.SDL_StartTextInput(window)) {
        std.debug.print("Error starting text input: {s}\n", .{SDL.SDL_GetError()});
        return error.SDL_StartTextInputFailed;
    }
    defer {
        if (!SDL.SDL_StopTextInput(window)) {
            std.debug.print("Error stopping text input: {s}\n", .{SDL.SDL_GetError()});
        }
    }

    const arena = init.arena.allocator();

    var editor = try Editor.init(arena);
    try editor.loadFile(init.io, "foo.rb");

    defer editor.deinit();

    while (!window_should_close) {
        var event: SDL.SDL_Event = undefined;
        while (SDL.SDL_PollEvent(&event)) {
            switch (event.type) {
                SDL.SDL_EVENT_QUIT => window_should_close = true,
                SDL.SDL_EVENT_KEY_DOWN => {
                    switch (event.key.scancode) {
                        SDL.SDL_SCANCODE_BACKSPACE => try editor.backspace(),
                        else => {},
                    }
                },
                SDL.SDL_EVENT_TEXT_INPUT => {
                    try editor.append(std.mem.span(event.text.text));
                },
                else => {},
            }
        }

        _ = SDL.SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
        _ = SDL.SDL_RenderClear(renderer);

        try editor.draw(renderer, font);

        _ = SDL.SDL_RenderPresent(renderer);
    }
}
