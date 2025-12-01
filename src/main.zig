const std = @import("std");
const zig_learn = @import("zig_learn");
const User = @import("models/user.zig").User;

var scale_val: f32 = 1.0;
var show_dialog_outside_frame: bool = false;
const dvui = @import("dvui");
const SDLBackend = @import("sdl-backend");

const window_icon_png = @embedFile("zig-favicon.png");

fn basic_demo() !void {
    const ns = [_]u8{ 48, 24, 33, 6 };
    const sl = ns[1..3];

    std.debug.print("sl: {any}\n", .{sl});

    const result = zig_learn.add(10, 20);
    std.debug.print("Result: {}\n", .{result});

    std.debug.print("Hello, {s}!\n", .{"World"});
    try std.fs.File.stdout().writeAll("Hello, World!\n");

    var optional_value: ?[]const u8 = null;
    std.debug.assert(optional_value == null);
    std.debug.print("\noptional 1\n type: {}\nvalue: {?s}\n", .{ @TypeOf(optional_value), optional_value });

    optional_value = "hi";

    std.debug.print("\noptional 2\n type: {}\nvalue: {?s}\n", .{ @TypeOf(optional_value), optional_value });
    // Prints to stderr, ignoring potential errors.
    // std.debug.print("All your {s} are belong to us.\n", .{"codebase"});
    // try zig_learn.bufferedPrint();

    var number_or_error: anyerror!i32 = error.ArgNotFound;
    std.debug.print("number_or_error: {!}\n", .{number_or_error});
    number_or_error = 1234;
}

fn read_file(allocator: std.mem.Allocator, path: []const u8) ![]u8 {
    var reader_buffer: [1024]u8 = undefined;
    // var file_buffer = try allocator.alloc(u8, 1024);
    // @memset(file_buffer[0..], 0);

    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    var reader = file.reader(reader_buffer[0..]);

    const file_contents = try reader.interface.readAlloc(allocator, try reader.getSize());

    // const nbytes = try reader.read(file_buffer[0..]);
    // return file_buffer[0..nbytes];
    return file_contents;
}

fn allocator_demo() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};

    const allocator = gpa.allocator();
    const path = "./build.zig";
    const file_contents = try read_file(allocator, path);
    const slice = file_contents[0..file_contents.len];

    std.debug.print("file contents len: {d}", .{file_contents.len});

    _ = slice;
}

const UserA = struct {
    id: u64,
    name: []const u8,
    email: []const u8,

    fn init(id: u64, name: []const u8, email: []const u8) UserA {
        return UserA{
            .id = id,
            .name = name,
            .email = email,
        };
    }

    fn print_name(self: UserA) void {
        std.debug.print("{s}\n", .{self.name});
    }
};

fn struct_demo() void {
    const u = UserA.init(1, "pedro", "email@gmail.com");
    u.print_name();
}

fn add(x: u8, y: u8) u8 {
    return x + y;
}

fn memory_demo() void {
    const r = add(5, 27);
    const y = 333;
    std.debug.print("r info: {}", .{r});
    _ = y;
}

threadlocal var tlx: i32 = 1222;
fn testTls() void {
    std.debug.print("x is {}\n", .{tlx});
    tlx += 1;

    std.debug.print("x is {}\n", .{tlx});
}

fn threadlocal_demo() !void {
    const thread1 = try std.Thread.spawn(.{}, testTls, .{});
    const thread2 = try std.Thread.spawn(.{}, testTls, .{});

    testTls();
    thread1.join();
    thread2.join();
}

fn str_demo() void {
    const str = "Hello, World!";
    std.debug.print("String: {s} {d}\n", .{ str, str[13] });
}

fn addFortyTwo(x: anytype) @TypeOf(x) {
    return x + 42;
}

fn quickDemo() void {
    const a = "0";
    std.debug.print("zero str: {x}\n", .{a});
    const result = addFortyTwo(10.0);
    std.debug.print("Result: {d}\n", .{result});

    const m_4x4 = [4][4]f32{
        [_]f32{ 1.0, 0.0, 0.0, 1.0 },
        [_]f32{ 0.0, 1.0, 0.0, 1.0 },
        [_]f32{ 0.0, 0.0, 1.0, 1.0 },
        [_]f32{ 0.0, 0.0, 0.0, 1.0 },
    };

    for (m_4x4) |row| {
        for (row) |col| {
            std.debug.print("{d} ", .{col});
        }
        std.debug.print("\n", .{});
    }

    const Empty = struct {};
    std.debug.print("{}\n", .{@sizeOf(Empty)});
}

fn Layer(comptime I: usize, comptime O: usize) type {
    return struct {
        inputs: usize,
        outputs: usize,

        const Self = @This();

        pub fn init() Self {
            return Self{
                .inputs = I,
                .outputs = O,
            };
        }

        pub fn input_len(self: *const Self) usize {
            return self.inputs;
        }

        pub fn output_len(self: *const Self) usize {
            return self.outputs;
        }
    };
}

fn dnnDemo() void {
    const layer1 = Layer(100, 20).init();
    var layer2 = Layer(20, 10).init();

    std.debug.print("layer1: {} layer2: {}\n", .{ @TypeOf(layer1), @TypeOf(layer2) });

    const l1_i = layer1.input_len();
    const l2_i = layer2.input_len();
    std.debug.print("l1_i= {} l2_i= {}\n", .{ l1_i, l2_i });
}

const Base64 = struct {
    _table: *const [64]u8,

    pub fn init() Base64 {
        const upper = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
        const lower = "abcdefghijklmnopqrstuvwxyz";
        const digits = "0123456789";
        const symbs = "+/";
        const table = upper ++ lower ++ digits ++ symbs;
        return Base64{ ._table = table };
    }

    pub fn _char_at(self: Base64, index: usize) u8 {
        return self._table[index];
    }
};

fn _calc_encode_length(input: []const u8) !usize {
    if (input.len < 3) {
        return 4;
    }

    const n_groups = try std.math.divCeil(usize, input.len, 3);

    return n_groups * 4;
}
fn _calc_decode_length(input: []const u8) !usize {
    const n_groups = std.math.divExact(usize, input.len, 4);

    var multiple_groups = n_groups * 3;
    var i = input.len - 1;

    while (i > 0) : (i -= 1) {
        if (input[i] == '=') {
            multiple_groups -= 1;
        } else {
            break;
        }
    }

    return multiple_groups;
}

fn eql(a: []const u8, b: []const u8) bool {
    if (a.len != b.len) return false;
    for (a, b, 0.., 0..) |a_e, b_e, i, j| {
        std.debug.print("a_e: {} b_e: {} i: {} j: {}\n", .{ a_e, b_e, i, j });
    }
    return std.mem.eql(u8, a, b);
}

fn moduleDemo() void {
    const user = User{ .power = 10000, .name = "ddd" };
    user.diagnose();
    User.diagnose(user);

    const a: []const u8 = "ddd";
    const b: []const u8 = "dad";

    const v = eql(a, b);
    std.debug.print("v: {}\n", .{v});
    // for (a, b) |a_e, b_e| {
    //     std.debug.print("a_e: {} b_e: {}\n", .{ a_e, b_e });
    // }
    // {
    //     const v = "ddd";
    //     std.debug.print("v res: {}", .{v});
    // }
    const pa = switch (a.len) {
        0 => "sane",
        1 => "one",
        2 => "two",
        3 => "three",
        else => "many",
    };
    std.debug.print("pa: {s}", .{pa});

    const un = 12222222222222222222222222221212121212121212121212121212121212121212121212121212121;
    std.debug.print("un: {} type= {}", .{ un * un, @TypeOf(un) });
}

fn ConstDim(comptime M: usize) type {
    return struct {
        fn size(_: @This()) usize {
            return M;
        }
    };
}

fn RuntimeDim(m: usize) type {
    return struct {
        fn size(_: @This()) usize {
            return m;
        }
    };
}

fn Tensor(comptime N: usize, comptime Shape: [N]usize, comptime T: type) type {
    return struct {
        data: [product(Shape)]T,
        fn product(comptime arr: [N]usize) usize {
            var result: usize = 1;
            inline for (arr) |dim| {
                result *= dim;
            }
            return result;
        }

        pub fn init(value: T) @This() {
            return @This(){ .data = [_]T{value} ** product(Shape) };
        }

        pub fn format(
            _: @This(),
            writer: *std.Io.Writer,
        ) std.Io.Writer.Error!void {
            try writer.print("Tensor({})", .{product(Shape)});
        }

        fn computeOffset(idx: [N]usize) usize {
            inline for (idx, 0..) |v, i| {
                // const shape_v = Shape[i];
                if (v >= Shape[i]) {
                    // const msg = std.fmt.Prin("Index {} out of bounds for dimension {} (max={})", .{ v, i, shape_v });
                    @panic("out of bounds");
                }
            }

            var offset: usize = 0;
            var stride: usize = 1;

            var d: usize = N;
            while (d > 0) : (d -= 1) {
                offset += idx[d - 1] * stride;
                stride *= Shape[d - 1];
            }

            return offset;
        }

        pub fn set(self: *@This(), idx: [N]usize, value: T) void {
            self.data[computeOffset(idx)] = value;
        }

        pub fn get(self: *const @This(), idx: [N]usize) T {
            return self.data[computeOffset(idx)];
        }
    };
}

fn tensorDemo() void {
    const aaa = .{ usize, i32 };
    std.debug.print("aaa: {}\n", .{aaa});

    const Tensor3 = Tensor(3, .{ 1, 2, 3 }, f32);
    const Tensor7 = Tensor(7, .{ 1, 2, 3, 4, 5, 6, 7 }, f80);
    std.debug.print("t1: {} t2: {}\n", .{ Tensor3, Tensor7 });

    const a1: [2]type = .{ Tensor3, Tensor7 };
    // _ = a1;
    inline for (a1, 0..) |tensor, idx| {
        std.debug.print("tensor: {} idx= {}\n", .{ tensor, idx });
    }
    // std.debug.print("a1: {any}", .{a1});

    const t1_type = @TypeOf(Tensor3);
    const t2_type = @TypeOf(Tensor7);
    if (t1_type == t2_type) {
        std.debug.print("same type: {}\n", .{t1_type});
    } else {
        std.debug.print("different type: t1= {} t2= {}\n", .{ t1_type, t2_type });
    }

    const t1 = Tensor3.init(10);
    const t2 = Tensor7.init(2.1);
    std.debug.print("t1: {f} t2: {f}\n", .{ t1, t2 });

    const e1 = t1.get(.{ 0, 1, 1 });
    _ = e1;
}

fn base64Demo() void {
    const a = "1234567890";
    const b = a[5..@min(a.len, 12)];
    std.debug.print("b: {s}\n", .{b});

    const base64 = Base64.init();
    std.debug.print("character at index 28: {c}", .{base64._char_at(28)});
}

pub fn main() !void {
    // tensorDemo();
    // try basic_demo();
    // try allocator_demo();
    // struct_demo();
    // memory_demo();
    // try threadlocal_demo();
    // str_demo();
    // quickDemo();
    // dnnDemo();
    // const x: f32 = 500.3;
    // const y: usize = @intFromFloat(x);
    // std.debug.print("x: {} y: {}\n", .{ x, y });

    // // _ = @TypeOf(true, 5.2);
    // std.debug.print("blah: {} field: {}\n", .{ @hasDecl(Foo, "nope"), @field(Foo, "nope") });
    try dvuiDemo();
    // try enumDemo();
}

fn enumDemo() anyerror!void {
    const Type = enum {
        ok,
        not_ok,
    };

    const c = Type.ok;
    std.debug.print("type info: {}\n", .{c});

    const Value = enum(u2) {
        zero,
        one,
        two,
        ok,
    };

    const v1 = Value.zero;

    const lv: u2 = 2;
    // lv += 1;

    const v2 = try std.meta.intToEnum(Value, lv);
    // const v2 = @as(Value, @enumFromInt(lv));
    std.debug.print("v1: {} v2: {}\n", .{ v1, v2 });

    const ComplexTypeTag = enum {
        ok,
        not_ok,
    };
    const ComplexType = union(ComplexTypeTag) { ok: u8, not_ok: void };

    const c1 = ComplexType{
        .ok = 42,
    };

    switch (c1) {
        .ok => |v| std.debug.print("v: {}\n", .{v}),
        .not_ok => std.debug.print("not ok\n", .{}),
    }
    std.debug.print("c1: {}\n", .{c1});

    const ComplexType1 = union(enum) {
        int: i32,
        boolean: bool,
        non,

        fn name(self: @This()) bool {
            return switch (self) {
                .int => |v| v > 0,
                .boolean => |v| v,
                .non => false,
            };
        }
    };
    var c2 = ComplexType1{ .boolean = false };
    switch (c2) {
        .int => |v| std.debug.print("int: {}\n", .{v}),
        .boolean => |v| std.debug.print("boolean: {}\n", .{v}),
        .non => std.debug.print("non\n", .{}),
    }
    c2.boolean = true;

    std.debug.print("c2: {} name= {}\n", .{ c2, c2.name() });
}

var points_count: usize = 1;

const MAX_POINTS_COUNT: usize = 1000;

fn dvuiDemo() !void {
    var gpa_instance = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = gpa_instance.allocator();

    var backend = try SDLBackend.initWindow(.{ .allocator = gpa, .size = .{ .w = 800.0, .h = 600.0 }, .min_size = .{ .w = 250.0, .h = 350.0 }, .vsync = true, .title = "DVUI SDL Standalone Example", .icon = window_icon_png });
    defer backend.deinit();

    // _ = SDLBackend.c.SDL_EnableScreenSaver();

    var win = try dvui.Window.init(@src(), gpa, backend.backend(), .{
        .theme = switch (backend.preferredColorScheme() orelse .light) {
            .light => dvui.Theme.builtin.adwaita_light,
            .dark => dvui.Theme.builtin.adwaita_dark,
        },
    });
    defer win.deinit();

    // try win.fonts.addBuiltinFontsForTheme(win.gpa, dvui.Theme.builtin.adwaita_light);

    var interrupted = false;

    main_loop: while (true) {
        // const start = std.time.nanoTimestamp();

        const nstime = win.beginWait(interrupted);

        try win.begin(nstime);
        try backend.addAllEvents(&win);

        _ = SDLBackend.c.SDL_SetRenderDrawColor(backend.renderer, 255, 255, 255, 255);
        _ = SDLBackend.c.SDL_RenderClear(backend.renderer);

        const keep_running = gui_frame(backend);
        if (!keep_running) break :main_loop;

        for (dvui.events()) |*event| {
            if (event.evt == .window and event.evt.window.action == .close) {
                std.debug.print("window close\n", .{});
                break :main_loop;
            }

            if (event.evt == .app and event.evt.app.action == .quit) {
                std.debug.print("app quit\n", .{});
                break :main_loop;
            }
        }

        // const before_add_point = std.time.nanoTimestamp();

        if (points_count < MAX_POINTS_COUNT) {
            points_count += 1;
            dvui.refresh(&win, @src(), null);
        }

        const end_micros = try win.end(.{});

        try backend.setCursor(win.cursorRequested());
        try backend.textInputRect(win.textInputRequested());

        try backend.renderPresent();

        const wait_event_micros = win.waitTime(end_micros);
        interrupted = try backend.waitEventTimeout(wait_event_micros);

        // const loop_end = std.time.nanoTimestamp();

        // std.debug.print("new loop: dur1= {} dur2= {}\n", .{ before_add_point - start, loop_end - before_add_point });
    }
}

fn formatFrequency(gpa: std.mem.Allocator, freq: f64) ![]const u8 {
    const exp = @log10(freq);
    const rounded_exp = std.math.round(exp);

    const val = std.math.pow(f64, 10, rounded_exp);

    if (rounded_exp < 3) {
        return try std.fmt.allocPrint(gpa, "{d:.0} Hz", .{val});
    } else if (rounded_exp < 6) {
        return try std.fmt.allocPrint(gpa, "{d:.0} kHz", .{val / 1e3});
    } else if (rounded_exp < 9) {
        return try std.fmt.allocPrint(gpa, "{d:.0} MHz", .{val / 1e6});
    } else {
        return try std.fmt.allocPrint(gpa, "{d:.0} GHz", .{val / 1e9});
    }
}

// const gridline_color = dvui.Color.gray;
const gridline_color = dvui.Color.fromHSLuv(0, 0, 0, 100);
const subtick_gridline_color = dvui.Color.fromHSLuv(0, 0, 0, 30);
// const subtick_gridline_color = dvui.Color.gray.lighten(-30);

var next_auto_color_idx: usize = 0;

fn auto_color() dvui.Color {
    const i = next_auto_color_idx;
    next_auto_color_idx += 1;
    // std.debug.print("i: {}\n", .{i});

    const golden_ratio = comptime (std.math.sqrt(5.0) - 1.0) / 2.0;
    // std.debug.print("golden ratio: {}\n", .{golden_ratio});

    const hue = @mod(@as(f32, @floatFromInt(i)) * golden_ratio * 360.0, 360.0);

    std.debug.print("hue value: {}\n", .{hue});
    const hsv_color =
        dvui.Color.HSV{ .h = hue, .s = 0.85, .v = 0.5, .a = 1.0 };
    return hsv_color.toColor();
}

fn gui_frame(_: SDLBackend) bool {
    // {
    //     var hbox = dvui.box(@src(), .{}, .{ .min_size_content = .{ .w = 800, .h = 600 }, .expand = .ratio });
    //     defer hbox.deinit();

    //     dvui.label(@src(), "Simple", .{}, .{});

    //     const xs: []const f64 = &.{ 0, 1, 2, 3, 4, 5 };
    //     const ys: []const f64 = &.{ 0, 4, 2, 6, 5, 9 };
    //     dvui.plotXY(@src(), .{ .xs = xs, .ys = ys }, .{});
    // }
    // {
    //     var hbox = dvui.box(@src(), .{ .dir = .horizontal }, .{});
    //     defer hbox.deinit();

    //     dvui.label(@src(), "Color and Thick", .{}, .{});

    //     const xs: []const f64 = &.{ 0, 1, 2, 3, 4, 5 };
    //     const ys: []const f64 = &.{ 9, 5, 6, 2, 4, 0 };
    //     dvui.plotXY(@src(), .{ .thick = 2, .xs = xs, .ys = ys, .color = dvui.themeGet().err.fill orelse .red }, .{});
    // }

    // var save: ?enum { png, jpg } = null;
    // {
    //     var hbox = dvui.box(@src(), .{ .dir = .horizontal }, .{});
    //     defer hbox.deinit();
    //     if (dvui.button(@src(), "Save png", .{}, .{})) {
    //         save = .png;
    //     }
    //     if (dvui.button(@src(), "Save jpg", .{}, .{})) {
    //         save = .jpg;
    //     }
    // }

    {
        var vbox = dvui.box(@src(), .{}, .{ .expand = .both });
        defer vbox.deinit();

        // var pic: ?dvui.Picture = null;
        // if (save != null) {
        //     pic = dvui.Picture.start(vbox.data().contentRectScale().r);
        // }

        const freq: f32 = 3;
        const Static = struct {
            var xaxis: dvui.PlotWidget.Axis = .{
                .name = "X Axis",
                .min = 0.05,
                .max = 2.0 * std.math.pi * freq,
                .ticks = .{
                    .side = .left_or_top,
                    // .locations = .{ .auto = .{ .tick_num_suggestion = 10 } },
                    .subticks = true,
                },
                .gridline_color = gridline_color,
                .subtick_gridline_color = subtick_gridline_color,
            };

            var yaxis: dvui.PlotWidget.Axis = .{
                .name = "Y Axis",
                // let plot figure out min
                .max = 1.2,
                .min = -1.2,
                .ticks = .{ .side = .both, .subticks = true },
                .gridline_color = gridline_color,
                .subtick_gridline_color = subtick_gridline_color,
            };
        };

        var plot = dvui.plot(@src(), .{
            .title = "Plot Title",
            .x_axis = &Static.xaxis,
            .y_axis = &Static.yaxis,
            .border_thick = 1.0,
            .mouse_hover = true,
            .spine_color = subtick_gridline_color,
        }, .{ .expand = .both, .gravity_x = 0.5, .gravity_y = 0.5 });

        next_auto_color_idx = 0;
        defer plot.deinit();

        const inner_ops: []const bool = &.{true};

        for (0..10) |i| {
            for (inner_ops) |op| {
                var s1 = plot.line();
                defer s1.deinit();

                // const points: usize = 1000;

                for (0..points_count + 1) |j| {
                    const v = 2.0 * std.math.pi * @as(f32, @floatFromInt(j)) / @as(f32, @floatFromInt(MAX_POINTS_COUNT)) * freq;

                    var vx = v;
                    for (0..i) |_| {
                        vx += std.math.pi / 2.0 / freq;
                    }

                    const fval: f32 = if (op) @sin(vx) else @cos(v);
                    // s1.point(@as(f64, @floatFromInt(j)) / @as(f64, @floatFromInt(points)), fval);
                    s1.point(v, fval);
                }

                const color = auto_color();
                // std.debug.print("s1 color: {f}\n", .{color});
                s1.stroke(1.8, color);
            }
        }

        // if (pic) |*p| {
        //     // `save` is not null because `pic` is not null
        //     p.stop();
        //     defer p.deinit();

        //     const filename: []const u8 = switch (save.?) {
        //         .png => "plot.png",
        //         .jpg => "plot.jpg",
        //     };

        //     if (dvui.backend.kind == .web) blk: {
        //         const min_buffer_size = @max(dvui.PNGEncoder.min_buffer_size, dvui.JPGEncoder.min_buffer_size);
        //         var writer = std.Io.Writer.Allocating.initCapacity(dvui.currentWindow().arena(), min_buffer_size) catch |err| {
        //             dvui.logError(@src(), err, "Failed to init writer for plot {t} image", .{save.?});
        //             break :blk;
        //         };
        //         defer writer.deinit();
        //         (switch (save.?) {
        //             .png => p.png(&writer.writer),
        //             .jpg => p.jpg(&writer.writer),
        //         }) catch |err| {
        //             dvui.logError(@src(), err, "Failed to write plot {t} image", .{save.?});
        //             break :blk;
        //         };
        //         // No need to call `writer.flush` because `Allocating` doesn't drain it's buffer anywhere
        //         dvui.backend.downloadData(filename, writer.written()) catch |err| {
        //             dvui.logError(@src(), err, "Could not download {s}", .{filename});
        //         };
        //     } else if (!dvui.useTinyFileDialogs) {
        //         dvui.toast(@src(), .{ .message = "Tiny File Dilaogs disabled" });
        //     } else {
        //         const maybe_path = dvui.dialogNativeFileSave(dvui.currentWindow().lifo(), .{ .path = filename }) catch null;
        //         if (maybe_path) |path| blk: {
        //             defer dvui.currentWindow().lifo().free(path);

        //             var file = std.fs.createFileAbsoluteZ(path, .{}) catch |err| {
        //                 dvui.log.debug("Failed to create file {s}, got {any}", .{ path, err });
        //                 dvui.toast(@src(), .{ .message = "Failed to create file" });
        //                 break :blk;
        //             };
        //             defer file.close();

        //             var buffer: [256]u8 = undefined;
        //             var writer = file.writer(&buffer);

        //             (switch (save.?) {
        //                 .png => p.png(&writer.interface),
        //                 .jpg => p.jpg(&writer.interface),
        //             }) catch |err| {
        //                 dvui.logError(@src(), err, "Failed to write plot {t} to file {s}", .{ save.?, path });
        //             };
        //             // End writing to file and potentially truncate any additional preexisting data
        //             writer.end() catch |err| {
        //                 dvui.logError(@src(), err, "Failed to end file write for {s}", .{path});
        //             };
        //         }
        //     }
        // }
    }

    // {
    //     const S = struct {
    //         var resistance: f64 = 159;
    //         var capacitance: f64 = 1e-6;

    //         var xaxis: dvui.PlotWidget.Axis = .{
    //             .name = "Frequency",
    //             .scale = .{ .log = .{} },
    //             .ticks = .{
    //                 .format = .{
    //                     .custom = formatFrequency,
    //                 },
    //                 .subticks = true,
    //             },
    //             .gridline_color = gridline_color,
    //             .subtick_gridline_color = subtick_gridline_color,
    //         };

    //         var yaxis: dvui.PlotWidget.Axis = .{
    //             .name = "Amplitude (dB)",
    //             .max = 10,
    //             .ticks = .{
    //                 .locations = .{
    //                     .auto = .{ .tick_num_suggestion = 10 },
    //                 },
    //             },
    //             .gridline_color = gridline_color,
    //         };
    //     };

    //     dvui.label(@src(), "Resistance (Ohm)", .{}, .{});
    //     const r_res = dvui.textEntryNumber(@src(), f64, .{
    //         .value = &S.resistance,
    //         .min = std.math.floatMin(f64),
    //     }, .{});

    //     dvui.label(@src(), "Capacitance (Farad)", .{}, .{});
    //     const c_res = dvui.textEntryNumber(@src(), f64, .{
    //         .value = &S.capacitance,
    //         .min = std.math.floatMin(f64),
    //     }, .{});

    //     const valid = r_res.value == .Valid and c_res.value == .Valid;

    //     const cutoff_angular_freq = 1 / (S.resistance * S.capacitance);

    //     dvui.label(@src(), "Cutoff frequency: {:.2} Hz", .{cutoff_angular_freq / (2 * std.math.pi)}, .{});

    //     var vbox = dvui.box(@src(), .{}, .{ .min_size_content = .{ .w = 300, .h = 100 }, .expand = .ratio });
    //     defer vbox.deinit();

    //     var plot = dvui.plot(@src(), .{
    //         .title = "RC low-pass filter",
    //         .x_axis = &S.xaxis,
    //         .y_axis = &S.yaxis,
    //         .border_thick = 2.0,
    //         .mouse_hover = true,
    //     }, .{ .expand = .both });
    //     defer plot.deinit();

    //     var s1 = plot.line();
    //     defer s1.deinit();

    //     const start_exp: f64 = 0;
    //     const end_exp: f64 = 8;
    //     const points: usize = 1000;
    //     const step: f64 = (end_exp - start_exp) / @as(f64, @floatFromInt(points));

    //     for (0..points) |i| {
    //         const exp = start_exp + step * @as(f64, @floatFromInt(i));

    //         const freq: f64 = std.math.pow(f64, 10, exp);
    //         const angular_freq: f64 = 2 * std.math.pi * freq;

    //         const tmp = angular_freq * S.resistance * S.capacitance;
    //         const amplitude = std.math.sqrt(1 / (1 + tmp * tmp));
    //         const amplitude_db: f64 = 20 * @log10(amplitude);
    //         s1.point(freq, amplitude_db);
    //     }
    //     s1.stroke(1, if (valid) dvui.themeGet().focus else dvui.Color.red);
    // }

    // {
    //     const S = struct {
    //         var stddev: f64 = 1.0;
    //         var mean: f64 = 0;
    //         var prng_seed: u64 = 2807233815221062137;
    //         var npoints: u32 = 64;
    //     };

    //     const Static = struct {
    //         var xaxis: dvui.PlotWidget.Axis = .{
    //             .name = "Value",
    //             .ticks = .{
    //                 .locations = .{
    //                     .auto = .{ .tick_num_suggestion = 9 },
    //                 },
    //             },
    //             .min = -2,
    //             .max = 2,
    //         };

    //         var yaxis: dvui.PlotWidget.Axis = .{
    //             .name = "Count",
    //             .ticks = .{
    //                 .locations = .{
    //                     .auto = .{ .tick_num_suggestion = 6 },
    //                 },
    //             },
    //             .max = 0,
    //         };
    //     };

    //     dvui.label(@src(), "Standard Deviation", .{}, .{});
    //     const s_res = dvui.textEntryNumber(@src(), f64, .{
    //         .value = &S.stddev,
    //     }, .{});

    //     dvui.label(@src(), "Mean", .{}, .{});
    //     const m_res = dvui.textEntryNumber(@src(), f64, .{
    //         .value = &S.mean,
    //     }, .{});

    //     dvui.label(@src(), "PRNG Seed", .{}, .{});
    //     const seed_res = dvui.textEntryNumber(@src(), u64, .{
    //         .value = &S.prng_seed,
    //     }, .{});

    //     dvui.label(@src(), "Number of Points", .{}, .{});
    //     const npoints_res = dvui.textEntryNumber(@src(), u32, .{
    //         .value = &S.npoints,
    //     }, .{});

    //     const valid = s_res.value == .Valid and m_res.value == .Valid and seed_res.value == .Valid and npoints_res.value == .Valid;

    //     var vbox = dvui.box(@src(), .{}, .{ .min_size_content = .{ .w = 300, .h = 100 }, .expand = .ratio });
    //     defer vbox.deinit();

    //     var default_prng: std.Random.DefaultPrng = .init(S.prng_seed);
    //     const prng = default_prng.random();

    //     var histogram: [64]f64 = undefined;
    //     @memset(histogram[0..], 0);

    //     Static.yaxis.max.? = 0;

    //     const scalar = @as(f64, @floatFromInt(histogram.len)) / (Static.xaxis.max.? - Static.xaxis.min.?);
    //     for (0..S.npoints) |_| {
    //         const val = prng.floatNorm(f64) * S.stddev + S.mean;
    //         if (val < Static.xaxis.min.? or val >= Static.xaxis.max.?) continue;

    //         const bin: usize = @intFromFloat((val - Static.xaxis.min.?) * scalar);
    //         histogram[bin] += 1;
    //         Static.yaxis.max.? = @max(Static.yaxis.max.?, histogram[bin]);
    //     }

    //     var plot = dvui.plot(@src(), .{
    //         .title = "Random Normal Values",
    //         .x_axis = &Static.xaxis,
    //         .y_axis = &Static.yaxis,
    //         .border_thick = 2.0,
    //         .mouse_hover = true,
    //     }, .{ .expand = .both });
    //     defer plot.deinit();

    //     const bar_width = (Static.xaxis.max.? - Static.xaxis.min.?) / @as(f64, @floatFromInt(histogram.len));
    //     for (histogram, 0..) |count, i| {
    //         const val = Static.xaxis.min.? + @as(f64, @floatFromInt(i)) * bar_width;
    //         plot.bar(.{
    //             .x = val,
    //             .y = 0,
    //             .w = bar_width,
    //             .h = count,
    //             .color = if (valid) dvui.themeGet().focus else dvui.Color.red,
    //         });
    //     }
    // }
    // {
    //     var hbox = dvui.box(@src(), .{ .dir = .horizontal }, .{ .style = .window, .background = true, .expand = .horizontal, .name = "main" });
    //     defer hbox.deinit();

    //     var m = dvui.menu(@src(), .horizontal, .{});
    //     defer m.deinit();

    //     if (dvui.menuItemLabel(@src(), "File", .{ .submenu = true }, .{})) |r| {
    //         var fw = dvui.floatingMenu(@src(), .{ .from = r }, .{});
    //         defer fw.deinit();
    //     }
    // }

    // var scroll = dvui.scrollArea(@src(), .{}, .{ .expand = .both });
    // defer scroll.deinit();

    // var tl = dvui.textLayout(@src(), .{}, .{ .expand = .horizontal, .font_style = .title_4 });
    // const lorem = "This example shows how to use dvui in a normal application.";
    // tl.addText(lorem, .{});
    // tl.deinit();

    // var tl2 = dvui.textLayout(@src(), .{}, .{ .expand = .horizontal });
    // tl2.addText(
    //     \\DVUI
    //     \\- paints the entire window
    //     \\- can show floating windows and dialogs
    //     \\- example menu at the top of the window
    //     \\- rest of the window is a scroll area
    // , .{});
    // tl2.addText("\n\n", .{});
    // tl2.addText("Framerate is variable and adjusts as needed for input events and animations.", .{});
    // tl2.addText("\n\n", .{});
    // // if (vsync) {
    // tl2.addText("Framerate is capped by vsync.", .{});
    // // } else {
    // //     tl2.addText("Framerate is uncapped.", .{});
    // // }
    // tl2.addText("\n\n", .{});
    // tl2.addText("Cursor is always being set by dvui.", .{});
    // tl2.addText("\n\n", .{});
    // if (dvui.useFreeType) {
    //     tl2.addText("Fonts are being rendered by FreeType 2.", .{});
    // } else {
    //     tl2.addText("Fonts are being rendered by stb_truetype.", .{});
    // }
    // tl2.deinit();

    // const label = if (dvui.Examples.show_demo_window) "Hide Demo Window" else "Show Demo Window";
    // if (dvui.button(@src(), label, .{}, .{})) {
    //     dvui.Examples.show_demo_window = !dvui.Examples.show_demo_window;
    // }

    // if (dvui.button(@src(), "Debug Window", .{}, .{})) {
    //     dvui.toggleDebugWindow();
    // }

    // {
    //     var scaler = dvui.scale(@src(), .{ .scale = &scale_val }, .{ .expand = .horizontal });
    //     defer scaler.deinit();

    //     {
    //         var hbox = dvui.box(@src(), .{ .dir = .horizontal }, .{});
    //         defer hbox.deinit();

    //         if (dvui.button(@src(), "Zoom In", .{}, .{})) {
    //             scale_val = @round(dvui.themeGet().font_body.size * scale_val + 1.0) / dvui.themeGet().font_body.size;
    //         }

    //         if (dvui.button(@src(), "Zoom Out", .{}, .{})) {
    //             scale_val = @round(dvui.themeGet().font_body.size * scale_val - 1.0) / dvui.themeGet().font_body.size;
    //         }
    //     }

    //     dvui.labelNoFmt(@src(), "Below is drawn directly by the backend, not going through DVUI.", .{}, .{ .margin = .{ .x = 4 } });

    //     var box = dvui.box(@src(), .{ .dir = .horizontal }, .{ .expand = .horizontal, .min_size_content = .{ .h = 40 }, .background = true, .margin = .{ .x = 8, .w = 8 } });
    //     defer box.deinit();

    //     // Here is some arbitrary drawing that doesn't have to go through DVUI.
    //     // It can be interleaved with DVUI drawing.
    //     // NOTE: This only works in the main window (not floating subwindows
    //     // like dialogs).

    //     // get the screen rectangle for the box
    //     const rs = box.data().contentRectScale();

    //     // rs.r is the pixel rectangle, rs.s is the scale factor (like for
    //     // hidpi screens or display scaling)
    //     var rect: if (SDLBackend.sdl3) SDLBackend.c.SDL_FRect else SDLBackend.c.SDL_Rect = undefined;
    //     if (SDLBackend.sdl3) rect = .{
    //         .x = (rs.r.x + 4 * rs.s),
    //         .y = (rs.r.y + 4 * rs.s),
    //         .w = (20 * rs.s),
    //         .h = (20 * rs.s),
    //     } else rect = .{
    //         .x = @intFromFloat(rs.r.x + 4 * rs.s),
    //         .y = @intFromFloat(rs.r.y + 4 * rs.s),
    //         .w = @intFromFloat(20 * rs.s),
    //         .h = @intFromFloat(20 * rs.s),
    //     };
    //     _ = SDLBackend.c.SDL_SetRenderDrawColor(backend.renderer, 255, 0, 0, 255);
    //     _ = SDLBackend.c.SDL_RenderFillRect(backend.renderer, &rect);

    //     rect.x += if (SDLBackend.sdl3) 24 * rs.s else @intFromFloat(24 * rs.s);
    //     _ = SDLBackend.c.SDL_SetRenderDrawColor(backend.renderer, 0, 255, 0, 255);
    //     _ = SDLBackend.c.SDL_RenderFillRect(backend.renderer, &rect);

    //     rect.x += if (SDLBackend.sdl3) 24 * rs.s else @intFromFloat(24 * rs.s);
    //     _ = SDLBackend.c.SDL_SetRenderDrawColor(backend.renderer, 0, 0, 255, 255);
    //     _ = SDLBackend.c.SDL_RenderFillRect(backend.renderer, &rect);

    //     _ = SDLBackend.c.SDL_SetRenderDrawColor(backend.renderer, 255, 0, 255, 255);

    //     if (SDLBackend.sdl3)
    //         _ = SDLBackend.c.SDL_RenderLine(backend.renderer, (rs.r.x + 4 * rs.s), (rs.r.y + 30 * rs.s), (rs.r.x + rs.r.w - 8 * rs.s), (rs.r.y + 30 * rs.s))
    //     else
    //         _ = SDLBackend.c.SDL_RenderDrawLine(backend.renderer, @intFromFloat(rs.r.x + 4 * rs.s), @intFromFloat(rs.r.y + 30 * rs.s), @intFromFloat(rs.r.x + rs.r.w - 8 * rs.s), @intFromFloat(rs.r.y + 30 * rs.s));
    // }

    // if (dvui.button(@src(), "Show Dialog From\nOutside Frame", .{}, .{})) {
    //     show_dialog_outside_frame = true;
    // }

    // // look at demo() for examples of dvui widgets, shows in a floating window
    // dvui.Examples.demo();

    // // check for quitting
    // for (dvui.events()) |*e| {
    //     // assume we only have a single window
    //     if (e.evt == .window and e.evt.window.action == .close) return false;
    //     if (e.evt == .app and e.evt.app.action == .quit) return false;
    // }

    return true;
}

const Foo = struct {
    nope: i32,
    pub var blah = "xxx";
    const hi = 1;
};

fn foo(comptime T: type, ptr: *T) T {
    ptr.* += 1;
    return ptr.*;
}

test "simple test" {
    const str = "123456789";
    const str1: []const u8 = str;

    for (str1) |c| {
        std.debug.print("{}|", .{c});
    }

    std.debug.print("str: {x} {}|\n", .{ str1, str[9] });

    // const a: f32 = 2.3;
    // const b = @as(u32, a);
    // std.debug.print("b: {}\n", .{b});
}

test "fuzz example" {
    const Context = struct {
        fn testOne(context: @This(), input: []const u8) anyerror!void {
            _ = context;
            // Try passing `--fuzz` to `zig build test` and see if it manages to fail this test case!
            try std.testing.expect(!std.mem.eql(u8, "canyoufindme", input));
        }
    };
    try std.testing.fuzz(Context{}, Context.testOne, .{});
}
