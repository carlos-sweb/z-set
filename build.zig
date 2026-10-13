const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const zmap_dep = b.dependency("zmap", .{ .target = target, .optimize = optimize });
    const zmap_module = zmap_dep.module("zmap");

    const zset_module = b.addModule("zset", .{
        .root_source_file = b.path("src/zset.zig"),
        .target = target,
        .optimize = optimize,
    });
    zset_module.addImport("zmap", zmap_module);

    const docs_library = b.addLibrary(.{
        .name = "zset",
        .root_module = zset_module,
    });
    const install_docs = b.addInstallDirectory(.{
        .source_dir = docs_library.getEmittedDocs(),
        .install_dir = .prefix,
        .install_subdir = "docs",
    });
    const docs_step = b.step("docs", "Generate API documentation in zig-out/docs");
    docs_step.dependOn(&install_docs.step);

    const test_step = b.step("test", "Run all tests");

    const test_files = [_][]const u8{
        "tests/zset_test.zig",
    };

    inline for (test_files) |test_file| {
        const unit_tests = b.addTest(.{
            .root_module = b.createModule(.{
                .root_source_file = b.path(test_file),
                .target = target,
                .optimize = optimize,
            }),
        });

        unit_tests.root_module.addImport("zset", zset_module);

        const run_unit_tests = b.addRunArtifact(unit_tests);
        test_step.dependOn(&run_unit_tests.step);
    }

    b.default_step = test_step;
}
