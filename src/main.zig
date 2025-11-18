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

pub fn main() !void {
    // try basic_demo();
    // try allocator_demo();
    // struct_demo();
    // memory_demo();
    // try threadlocal_demo();
    // str_demo();
    quickDemo();
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
