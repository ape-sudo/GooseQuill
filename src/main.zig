const std = @import("std");

pub const c = @cImport({
    @cInclude("SDL3/SDL.h");
    @cInclude("SDL3_ttf/SDL_ttf.h");
});

const gq = @import("GooseQuill");

pub fn main() u8 {
    gq.hello_world();

    const WIDTH = 800;
    const HEIGHT = 600;

    if (!c.SDL_Init(c.SDL_INIT_VIDEO)) {
        std.debug.print("CANNOT INIT SDL: {s}\n", .{c.SDL_GetError()});
        return 1;
    }

    const window = c.SDL_CreateWindow("GooseQuill", WIDTH, HEIGHT, 0);

    if (window == null) {
        std.debug.print("CANNOT CREATE WINDOW\n", .{});
        return 1;
    }

    const renderer = c.SDL_CreateRenderer(window, null);

    if (renderer == null) {
        std.debug.print("CANNOT CREATE REDNERED\n", .{});
        return 1;
    }

    const font_path = "main_font.ttf";

    if (!c.TTF_Init()) {
        std.debug.print("TTF_Init failed: {s}\n", .{c.SDL_GetError()});
        return 1;
    }

    const font = c.TTF_OpenFont(font_path, 22);
    if (font == null) {
        std.debug.print("TTF_OpenFont failed: {s}\n", .{c.SDL_GetError()});
        return 1;
    }

    const surface = c.TTF_RenderText_Blended(font, "Hello World", 0, .{ .r = 255, .g = 255, .b = 255, .a = 255 });

    const texture = c.SDL_CreateTextureFromSurface(renderer, surface);

    const rect_dst: c.SDL_FRect = .{ .x = 10, .y = 10, .w = @floatFromInt(surface.*.w), .h = @floatFromInt(surface.*.h) };

    var window_should_close: bool = false;

    while (!window_should_close) {
        var event: c.SDL_Event = undefined;
        while (c.SDL_PollEvent(&event)) {
            if (event.type == c.SDL_EVENT_QUIT) {
                window_should_close = true;
            }
        }

        _ = c.SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
        _ = c.SDL_RenderClear(renderer);

        _ = c.SDL_RenderTexture(renderer, texture, null, &rect_dst);

        _ = c.SDL_RenderPresent(renderer);
    }

    c.SDL_DestroyTexture(texture);
    c.SDL_DestroySurface(surface);
    c.TTF_CloseFont(font);

    c.SDL_DestroyRenderer(renderer);
    c.SDL_DestroyWindow(window);

    c.TTF_Quit();
    c.SDL_Quit();
    return 0;
}
