const std = @import("std");
const SDL = @import("./sdl.zig").SDL;

pub const CommandPrompt = struct {
    allocator: std.mem.Allocator,
    buffer: std.ArrayList(u8),

    pub fn init(allocator: std.mem.Allocator) !CommandPrompt {
        var buffer = try std.ArrayList(u8).initCapacity(allocator, 1024);
        try buffer.append(allocator, 0);
        return CommandPrompt{ .buffer = buffer, .allocator = allocator };
    }

    pub fn draw(self: *CommandPrompt, renderer: *SDL.SDL_Renderer, font: *SDL.TTF_Font, window: *SDL.SDL_Window) !void {
        if (self.buffer.items.len <= 1) {
            return;
        }

        const surface = SDL.TTF_RenderText_Blended(font, self.buffer.items.ptr, 0, .{ .r = 255, .g = 255, .b = 255, .a = 255 });
        defer SDL.SDL_DestroySurface(surface);

        const texture = SDL.SDL_CreateTextureFromSurface(renderer, surface);
        defer SDL.SDL_DestroyTexture(texture);

        var window_w: c_int = 0;
        var window_h: c_int = 0;

        _ = SDL.SDL_GetWindowSize(window, &window_w, &window_h);

        const rect_dst: SDL.SDL_FRect = .{ .x = 0, .y = @floatFromInt(window_h - surface.*.h), .w = @floatFromInt(surface.*.w), .h = @floatFromInt(surface.*.h) };

        _ = SDL.SDL_SetRenderDrawColor(renderer, 255, 0, 0, 255);
        _ = SDL.SDL_RenderRect(renderer, &rect_dst);

        _ = SDL.SDL_RenderTexture(renderer, texture, null, &rect_dst);
    }

    pub fn append(self: *CommandPrompt, string: []const u8) !void {
        _ = self.buffer.pop();
        try self.buffer.appendSlice(self.allocator, string);
        try self.buffer.append(self.allocator, 0);
    }

    pub fn backspace(self: *CommandPrompt) !void {
        if (self.buffer.items.len <= 1) {
            return;
        }
        _ = self.buffer.pop();
        _ = self.buffer.pop();
        try self.buffer.append(self.allocator, 0);
    }

    pub fn deinit(self: *CommandPrompt) void {
        self.buffer.deinit(self.allocator);
    }
};
