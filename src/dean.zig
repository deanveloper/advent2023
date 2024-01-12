const std = @import("std");

pub fn readFromExe(allocator: std.mem.Allocator, relpath: []const u8) ![]u8 {
    const abspath = std.fs.path.join(allocator, &.{ "resources", relpath }) catch return error.AssemblingPath;
    defer allocator.free(abspath);

    const file = std.fs.cwd().openFile(abspath, .{}) catch return error.OpeningFile;
    defer file.close();

    const bytes = file.readToEndAlloc(allocator, 1_000_000) catch return error.ReadingFile;
    return bytes;
}
