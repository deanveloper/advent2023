const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // make 'dean.zig' available as just "dean"
    const deanModule = b.addModule("dean", .{ .source_file = .{ .path = "src/dean.zig" } });

    const test_step = b.step("test", "Runs tests");

    const dayOption = b.option(u32, "day", "Filter tests by day");

    var src_dir = try std.fs.cwd().openDir("src", .{ .iterate = true });
    defer src_dir.close();
    var files = src_dir.iterate();

    while (try files.next()) |file| {
        if (file.kind != .directory or file.name.len != 5) {
            continue;
        }

        if (dayOption) |day| {
            if (day >= 100) {
                return error.DayLimitIs100;
            }
            var dayStr: [2]u8 = undefined;
            var fbs = std.io.fixedBufferStream(&dayStr);
            try std.fmt.formatInt(day, 10, .lower, .{ .fill = '0', .alignment = .right, .width = 2 }, fbs.writer());
            var dayAsDir: [5]u8 = undefined;
            @memcpy(dayAsDir[0..3], "day");
            @memcpy(dayAsDir[3..5], &dayStr);
            if (!std.mem.eql(u8, &dayAsDir, file.name)) {
                continue;
            }
        }

        if (std.mem.startsWith(u8, file.name, "day0") and file.name.len > 4) {
            const path = try std.fs.path.join(b.allocator, &[_][]const u8{ "src", file.name, "problem.zig" });

            const tester = b.addTest(.{
                .name = file.name,
                .root_source_file = .{ .path = path },
                .target = target,
                .optimize = optimize,
            });
            tester.addModule("dean", deanModule);
            test_step.dependOn(&b.addRunArtifact(tester).step);
        }
    }
}
