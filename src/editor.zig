const std = @import("std");
const SDL = @import("./sdl.zig").SDL;

pub const Editor = struct {
    allocator: std.mem.Allocator,
    buffer: std.ArrayList(u8),

    pub fn init(allocator: std.mem.Allocator) !Editor {
        var buffer = try std.ArrayList(u8).initCapacity(allocator, 1024);
        try buffer.append(allocator, 0);
        return Editor{ .buffer = buffer, .allocator = allocator };
    }

    pub fn draw(self: *Editor, renderer: *SDL.SDL_Renderer, font: *SDL.TTF_Font) !void {
        if (self.buffer.items.len <= 1) {
            return;
        }

        const surface = SDL.TTF_RenderText_Blended(font, self.buffer.items.ptr, 0, .{ .r = 255, .g = 255, .b = 255, .a = 255 });
        defer SDL.SDL_DestroySurface(surface);

        const texture = SDL.SDL_CreateTextureFromSurface(renderer, surface);
        defer SDL.SDL_DestroyTexture(texture);

        const rect_dst: SDL.SDL_FRect = .{ .x = 0, .y = 0, .w = @floatFromInt(surface.*.w), .h = @floatFromInt(surface.*.h) };

        _ = SDL.SDL_RenderTexture(renderer, texture, null, &rect_dst);
    }

    pub fn append(self: *Editor, string: []const u8) !void {
        _ = self.buffer.pop();
        try self.buffer.appendSlice(self.allocator, string);
        try self.buffer.append(self.allocator, 0);
    }

    pub fn loadFile(self: *Editor, io: std.Io, path: []const u8) !void {
        const Dir = std.Io.Dir;
        const dir = Dir.cwd();

        const content = try Dir.readFileAlloc(dir, io, path, self.allocator, std.Io.Limit.limited(std.math.maxInt(usize)));

        defer self.allocator.free(content);

        self.buffer.clearRetainingCapacity();

        try self.buffer.appendSlice(self.allocator, content);
        try self.buffer.append(self.allocator, 0);
    }

    pub fn backspace(self: *Editor) !void {
        if (self.buffer.items.len <= 1) {
            return;
        }
        _ = self.buffer.pop();
        _ = self.buffer.pop();
        try self.buffer.append(self.allocator, 0);
    }

    pub fn deinit(self: *Editor) void {
        self.buffer.deinit(self.allocator);
    }
};
