const std = @import("std");
const SDL = @import("./sdl.zig").SDL;

pub fn draw(renderer: *SDL.SDL_Renderer, font: *SDL.TTF_Font) void {
    const surface = SDL.TTF_RenderText_Blended(font, "Hello World", 0, .{ .r = 255, .g = 255, .b = 255, .a = 255 });
    defer SDL.SDL_DestroySurface(surface);

    const texture = SDL.SDL_CreateTextureFromSurface(renderer, surface);
    defer SDL.SDL_DestroyTexture(texture);

    const rect_dst: SDL.SDL_FRect = .{ .x = 0, .y = 0, .w = @floatFromInt(surface.*.w), .h = @floatFromInt(surface.*.h) };

    _ = SDL.SDL_RenderTexture(renderer, texture, null, &rect_dst);
}
