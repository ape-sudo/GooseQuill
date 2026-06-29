const std = @import("std");
const SDL = @import("./sdl.zig").SDL;

pub const CommandPrompt = struct {
    allocator: std.mem.Allocator,
    buffer: std.ArrayList(u8),
    prompt: std.ArrayList(u8),

    pub fn init(allocator: std.mem.Allocator) !CommandPrompt {
        var buffer = try std.ArrayList(u8).initCapacity(allocator, 1024);
        try buffer.append(allocator, 0);

        var prompt = try std.ArrayList(u8).initCapacity(allocator, 1024);
        try prompt.append(allocator, 0);

        return CommandPrompt{ .buffer = buffer, .prompt = prompt, .allocator = allocator };
    }

    pub fn draw(self: *CommandPrompt, renderer: *SDL.SDL_Renderer, font: *SDL.TTF_Font, window: *SDL.SDL_Window) !void {

        const prompt_surface = SDL.TTF_RenderText_Blended(font, self.prompt.items.ptr, 0, .{ .r = 255, .g = 255, .b = 255, .a = 255 });
        defer SDL.SDL_DestroySurface(prompt_surface);

        const texture_prompt = SDL.SDL_CreateTextureFromSurface(renderer, prompt_surface);
        defer SDL.SDL_DestroyTexture(texture_prompt);


        var window_w: c_int = 0;
        var window_h: c_int = 0;

        _ = SDL.SDL_GetWindowSize(window, &window_w, &window_h);

        const box_rect: SDL.SDL_FRect = .{ .x = 0, .y = @floatFromInt(window_h - prompt_surface.*.h), .w = @floatFromInt(window_w), .h = @floatFromInt(prompt_surface.*.h) };
        const promt_rect: SDL.SDL_FRect = . { .x = 0, .y = @floatFromInt(window_h - prompt_surface.*.h), .w = @floatFromInt(prompt_surface.*.w), .h = @floatFromInt(prompt_surface.*.h) };
        if (self.buffer.items.len > 1) {
            const surface = SDL.TTF_RenderText_Blended(font, self.buffer.items.ptr, 0, .{ .r = 255, .g = 255, .b = 255, .a = 255 });
            defer SDL.SDL_DestroySurface(surface);

            const texture = SDL.SDL_CreateTextureFromSurface(renderer, surface);
            defer SDL.SDL_DestroyTexture(texture);

            const command_input_rect: SDL.SDL_FRect = .{ .x = @floatFromInt(prompt_surface.*.w), .y = @floatFromInt(window_h - prompt_surface.*.h), .w = @floatFromInt(surface.*.w), .h = @floatFromInt(surface.*.h) };
            _ = SDL.SDL_RenderTexture(renderer, texture, null, &command_input_rect);
        }

        _ = SDL.SDL_SetRenderDrawColor(renderer, 128, 128, 128, 255);

        _ = SDL.SDL_RenderRect(renderer, &box_rect);
        _ = SDL.SDL_RenderTexture(renderer, texture_prompt, null, &promt_rect);
    }

    pub fn append(self: *CommandPrompt, string: []const u8) !void {
        _ = self.buffer.pop();
        try self.buffer.appendSlice(self.allocator, string);
        try self.buffer.append(self.allocator, 0);
    }

    pub fn set_prompt(self: *CommandPrompt, string: []const u8) !void {
        self.prompt.clearRetainingCapacity();
        try self.prompt.appendSlice(self.allocator, string);
        try self.prompt.append(self.allocator, 0);
    }

    pub fn clear_buffer(self: *CommandPrompt) !void {
        self.buffer.clearRetainingCapacity();
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
        self.prompt.deinit(self.allocator);
    }

    // if command -- open file
    // clear = cp. buffer
    // change prompt = enter file path:
    //
    // pub fn open_file()
};
