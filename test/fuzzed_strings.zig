const std = @import("std");
const zua = @import("zua");
const lex = zua.lex;
const parseString = zua.parse_literal.parseString;

// Tests for comparing parsed strings between Zua and Lua.
// Expects @import("build_options").fuzzed_strings_inputs_dir to be a path to
// a directory containing a corpus of inputs to test and
// @import("build_options").fuzzed_strings_outputs_dir to be a path to a
// directory containing the corresponding expected string after
// parsing.
//
// A usable inputs/outputs pair can be obtained from
// https://github.com/squeek502/fuzzing-lua

const verboseTestPrinting = false;

const build_options = @import("build_options");
const inputs_dir_opt = build_options.fuzzed_strings_inputs_dir;
const outputs_dir_opt = build_options.fuzzed_strings_outputs_dir;

test "string input/output pairs" {
    var arena_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_allocator.deinit();
    var allocator = &arena_allocator.allocator;

    // resolve these now since Zig's std lib on Windows rejects paths with / as the path sep
    const inputs_dir_path = try std.fs.path.resolve(allocator, &[_][]const u8{inputs_dir_opt});
    const outputs_dir_path = try std.fs.path.resolve(allocator, &[_][]const u8{outputs_dir_opt});

    var inputs_dir = try std.fs.cwd().openDir(inputs_dir_path, .{ .iterate = true });
    defer inputs_dir.close();
    var outputs_dir = try std.fs.cwd().openDir(outputs_dir_path, .{});
    defer outputs_dir.close();

    var n: usize = 0;
    var inputs_iterator = inputs_dir.iterate();
    while (try inputs_iterator.next()) |entry| {
        if (entry.kind != .File) continue;

        if (verboseTestPrinting) {
            std.debug.warn("\n{s}\n", .{entry.name});
        }
        const contents = try inputs_dir.readFileAlloc(allocator, entry.name, std.math.maxInt(usize));
        defer allocator.free(contents);

        const expectedContents = try outputs_dir.readFileAlloc(allocator, entry.name, std.math.maxInt(usize));
        defer allocator.free(expectedContents);

        var lexer = lex.Lexer.init(contents, "fuzz");
        while (true) {
            const token = lexer.next() catch |e| {
                break;
            };
            if (token.id == lex.Token.Id.eof) break;
            if (token.id != lex.Token.Id.string) continue;

            const string_source = contents[token.start..token.end];
            var buf = try allocator.alloc(u8, string_source.len);
            defer allocator.free(buf);
            const parsed = parseString(string_source, buf);
            if (verboseTestPrinting) {
                std.debug.warn("got\n{x}\n", .{parsed});
                std.debug.warn("expected\n{x}\n", .{expectedContents});
            }
            std.testing.expectEqualSlices(u8, expectedContents, parsed);
        }
        n += 1;
    }
    std.debug.warn("\n{} input/output pairs checked...\n", .{n});
}
