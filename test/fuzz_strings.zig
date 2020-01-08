const std = @import("std");
const zua = @import("zua");
const lex = zua.lex;
const parse = zua.parse;

// Tests for comparing parsed strings between Zua and Lua.
// Expects @import("build_options").fuzz_strings_inputs_dir to be a path to
// a directory containing a corpus of inputs to test and 
// @import("build_options").fuzz_strings_outputs_dir to be a path to a
// directory containing the corresponding expected string after
// parsing.
//
// A usable inputs/outputs pair can be obtained from
// https://github.com/squeek502/fuzzing-lua

const verboseTestPrinting = false;

const build_options = @import("build_options");
const inputs_dir_opt = build_options.fuzz_strings_inputs_dir;
const outputs_dir_opt = build_options.fuzz_strings_outputs_dir;

test "string input/output pairs" {
    var arena_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_allocator.deinit();
    var allocator = &arena_allocator.allocator;

    // resolve these now since Zig's std lib on Windows rejects paths with / as the path sep
    const inputs_dir = try std.fs.path.resolve(allocator, &[_][]const u8{ inputs_dir_opt });
    const outputs_dir = try std.fs.path.resolve(allocator, &[_][]const u8{ outputs_dir_opt });

    var walker = try std.fs.walkPath(allocator, inputs_dir);
    defer walker.deinit();
    var path_buffer = try std.Buffer.init(allocator, outputs_dir);
    defer path_buffer.deinit();
    var result_buffer: [1024 * 1024]u8 = undefined;

    var n: usize = 0;
    while (try walker.next()) |entry| {
        if (verboseTestPrinting) {
            std.debug.warn("\n{}\n", .{entry.basename});
        }
        const contents = try entry.dir.readFileAlloc(allocator, entry.basename, std.math.maxInt(usize));
        defer allocator.free(contents);

        path_buffer.shrink(outputs_dir.len);
        try path_buffer.appendByte(std.fs.path.sep);
        try path_buffer.append(entry.basename);
        const expectedContents = try std.io.readFileAlloc(allocator, path_buffer.toSliceConst());
        defer allocator.free(expectedContents);

        var lexer = lex.DefaultLexer.init(contents);
        while (true) {
            const token = lexer.next() catch |e| {
                break;
            };
            if (token.id == lex.Token.Id.Eof) break;
            if (token.id != lex.Token.Id.String) continue;

            const string_source = contents[token.start..token.end];
            var buf = try allocator.alloc(u8, string_source.len);
            defer allocator.free(buf);
            const parsed = parse.Parser.parseStringLiteral(string_source, buf);
            if (verboseTestPrinting) {
                std.debug.warn("got\n{x}\n", .{parsed});
                std.debug.warn("expected\n{x}\n", .{expectedContents});
            }
            std.testing.expectEqualSlices(u8, expectedContents, parsed);
        }
        n += 1;
    }
    std.debug.warn("{} input/output pairs checked...", .{n});
}