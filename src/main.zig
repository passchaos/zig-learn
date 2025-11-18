const std = @import("std");
const zig_learn = @import("zig_learn");

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

const User = struct {
    id: u64,
    name: []const u8,
    email: []const u8,

    fn init(id: u64, name: []const u8, email: []const u8) User {
        return User{
            .id = id,
            .name = name,
            .email = email,
        };
    }

    fn print_name(self: User) void {
        std.debug.print("{s}\n", .{self.name});
    }
};

fn struct_demo() void {
    const u = User.init(1, "pedro", "email@gmail.com");
    u.print_name();
}

fn add(x: u8, y: u8) *const u8 {
    const result = x + y;
    return &result;
}

fn memory_demo() void {
    const r = add(5, 27);
    const y = 333;
    std.debug.print("r info: {}", .{r.*});
    // _ = r;
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

pub fn Array(comptime T: type, comptime N: ?usize, comptime Shape: ?[]const usize) type {
    return struct {
        shape: if (Shape) |s| [s.len]usize else if (N) |n| [n]usize else []usize,
        data: []T,

        pub fn init(allocator: *std.mem.Allocator, shape: if (Shape) |s| [s.len]usize else if (N) |n| [n]usize else []usize) !Array(T, N, Shape) {
            var total: usize = 1;
            for (shape) |d| total *= d;
            const buf = try allocator.alloc(T, total);
            return Array(T, N, Shape){ .shape = shape, .data = buf };
        }

        pub fn totalSize(self: *const Array(T, N, Shape)) usize {
            var total: usize = 1;
            for (self.shape) |d| total *= d;
            return total;
        }

        pub fn coordToIndex(self: *const Array(T, N, Shape), coord: if (Shape) |s| [s.len]usize else if (N) |n| [n]usize else []usize) usize {
            if (coord.len != self.shape.len) @panic("dimension mismatch");
            var idx: usize = 0;
            var stride: usize = 1;
            var i: usize = self.shape.len;
            while (i > 0) : (i -= 1) {
                idx += coord[i - 1] * stride;
                stride *= self.shape[i - 1];
            }
            return idx;
        }

        pub fn set(self: *Array(T, N, Shape), coord: anytype, value: T) void {
            self.data[self.coordToIndex(coord)] = value;
        }

        pub fn get(self: *const Array(T, N, Shape), coord: anytype) T {
            return self.data[self.coordToIndex(coord)];
        }

        pub fn deinit(self: *Array(T, N, Shape), allocator: *std.mem.Allocator) void {
            allocator.free(self.data);
        }
    };
}

pub fn arrayDemo() !void {
    var allocator = std.heap.page_allocator;

    // 1. 编译时维度和形状固定
    var arr_static = try Array(u32, 2, &.{ 3, 4 }).init(&allocator, [2]usize{ 3, 4 });
    arr_static.set([2]usize{ 1, 2 }, 42);
    std.debug.print("Static value: {}\n", .{arr_static.get([2]usize{ 1, 2 })});
    arr_static.deinit(&allocator);

    // 2. 编译时维度固定，形状运行时决定
    var arr_multi = try Array(u32, 2, null).init(&allocator, [2]usize{ 5, 6 });
    arr_multi.set([2]usize{ 2, 3 }, 99);
    std.debug.print("Multi value: {}\n", .{arr_multi.get([2]usize{ 2, 3 })});
    arr_multi.deinit(&allocator);

    // 3. 维度和形状都运行时决定
    var shape = try allocator.alloc(usize, 3);
    shape[0] = 2;
    shape[1] = 3;
    shape[2] = 4;
    var arr_dyn = try Array(u32, null, null).init(&allocator, shape);
    arr_dyn.set(&[_]usize{ 1, 2, 3 }, 123);
    std.debug.print("Dyn value: {}\n", .{arr_dyn.get(&[_]usize{ 1, 2, 3 })});
    arr_dyn.deinit(&allocator);
    allocator.free(shape);
}

const Base64 = struct {
    _table: *const [64]u8,

    pub fn init() Base64 {
        const upper = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
        const lower = "abcdefghijklmnopqrstuvwxyz";
        const digits = "0123456789";
        const symbs = "+/";
        const padding = "=";
        const table = upper ++ lower ++ digits ++ symbs ++ padding;
        return Base64{ ._table = table };
    }

    pub fn _char_at(self: Base64, index: usize) u8 {
        return self._table[index];
    }
};

pub fn main() !void {
    // try basic_demo();
    // try allocator_demo();
    // struct_demo();
    // memory_demo();
    // try threadlocal_demo();
    // str_demo();
    // quickDemo();
    // dnnDemo();
    arrayDemo();
}

test "simple test" {
    const gpa = std.testing.allocator;
    var list: std.ArrayList(i32) = .empty;
    defer list.deinit(gpa); // Try commenting this out and see if zig detects the memory leak!
    try list.append(gpa, 42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
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
