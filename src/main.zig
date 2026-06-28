const std = @import("std");

const SDL = @import("./sdl.zig").SDL;
const Editor = @import("./editor.zig").Editor;
const CommandPrompt = @import("./command_prompt.zig").CommandPrompt;

const Command = enum {
    open_file,
    save_file,
    empty,
};

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
    try editor.loadFile(init.io, "./zig-out/bin/foo.rb");

    defer editor.deinit();

    var cp = try CommandPrompt.init(arena);
    try cp.set_prompt("enter command: ");
    try cp.set_prompt("enter command: ");
    defer cp.deinit();

    var command_prompt_on = false;
    var error_until: u64 = 0;
    var waiting_for_command_args = false;
    var last_command = Command.empty;

    while (!window_should_close) {
        var event: SDL.SDL_Event = undefined;
        while (SDL.SDL_PollEvent(&event)) {
            switch (event.type) {
                SDL.SDL_EVENT_QUIT => window_should_close = true,
                SDL.SDL_EVENT_KEY_DOWN => {
                    if (SDL.SDL_KMOD_ALT != 0 and event.key.scancode == SDL.SDL_SCANCODE_X) {
                        command_prompt_on = true;
                    } else if (event.key.scancode == SDL.SDL_SCANCODE_RETURN) {
                        if (command_prompt_on) {
                            if (!waiting_for_command_args) {
                                std.debug.print("2\n", .{});
                                const slice = cp.buffer.items[0 .. cp.buffer.items.len - 1];
                                if (std.mem.eql(u8, "open-file", slice)) {
                                    last_command = Command.open_file;
                                    try cp.set_prompt("file name: ");
                                    try cp.clear_buffer();
                                    waiting_for_command_args = true;
                                } else if (std.mem.eql(u8, "save-file", slice)) {
                                    last_command = Command.save_file;
                                    try cp.set_prompt("save: ");
                                    try cp.clear_buffer();
                                    try cp.append(editor.absolute_path);
                                    waiting_for_command_args = true;
                                } else {
                                    last_command = Command.empty;
                                    try cp.set_prompt("command not found...");
                                    try cp.clear_buffer();
                                    error_until = SDL.SDL_GetTicks() + 500;
                                }
                            } else {
                                if (event.key.scancode == SDL.SDL_SCANCODE_RETURN) {
                                   switch (last_command) {
                                      Command.open_file => {
                                        const slice = cp.buffer.items[0 .. cp.buffer.items.len - 1];
                                        editor.loadFile(init.io, slice) catch {
                                            try cp.set_prompt("file not found...");
                                            error_until = SDL.SDL_GetTicks() + 500;
                                        };
                                      },
                                      Command.save_file => {
                                          const path = cp.buffer.items[0 .. cp.buffer.items.len - 1];
                                          try editor.saveFile(init.io, path);
                                          std.debug.print("SAVING FILE", .{});
                                      },
                                      else => {}
                                   }
                                    command_prompt_on = false;
                                    waiting_for_command_args = false;
                                    try cp.set_prompt("enter command: ");
                                    try cp.clear_buffer();
                                }
                            }
                        }
                    } else {
                        switch (event.key.scancode) {
                            SDL.SDL_SCANCODE_BACKSPACE => {
                                if (command_prompt_on) {
                                    try cp.backspace();
                                } else {
                                    try editor.backspace();
                                }
                            },
                            else => {},
                        }
                    }
                },
                SDL.SDL_EVENT_TEXT_INPUT => {
                    if (command_prompt_on) {
                        try cp.append(std.mem.span(event.text.text));
                    } else {
                        try editor.append(std.mem.span(event.text.text));
                    }
                },
                else => {},
            }

       }

       if (command_prompt_on) {
           if (SDL.SDL_GetTicks() >= error_until and error_until != 0) {
               last_command = Command.empty;
               command_prompt_on = false;
               waiting_for_command_args = false;
               error_until = 0;
               try cp.set_prompt("enter command: ");
           }
       }

        _ = SDL.SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
        _ = SDL.SDL_RenderClear(renderer);

        try editor.draw(renderer, font);
        if (command_prompt_on) {
            try cp.draw(renderer, font, window.?);
        }

        _ = SDL.SDL_RenderPresent(renderer);
    }
}
