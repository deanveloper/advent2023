const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) !void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    // make 'dean.zig' available as just "dean"
    const deanModule = b.addModule("dean", .{ .source_file = .{ .path = "src/dean.zig" } });

    const test_step = b.step("test", "Runs tests");

    var src_dir = try std.fs.cwd().openDir("src", .{ .iterate = true });
    defer src_dir.close();
    var files = src_dir.iterate();

    while (try files.next()) |file| {
        if (file.kind != .directory or file.name.len != 5) {
            continue;
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
