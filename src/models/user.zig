const std = @import("std");

pub const User = struct {
    power: u64,
    name: []const u8,

    const self = @This();

    const SUPER_POWER = 9000;
    pub fn diagnose(user: self) void {
        std.debug.print("power type: {} str type: {}\n", .{ @TypeOf(user.name), @TypeOf("Guko") });
        if (user.power >= SUPER_POWER) {
            std.debug.print("User {s} has super power!\n", .{user.name});
        }
    }
};
