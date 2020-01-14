Zua
===

An attempt at a [Lua](https://lua.org) 5.1 implementation in [Zig](https://ziglang.org).

Goals, in order of priority:
1. Learn more about Lua internals
2. Learn more about Zig
3. Anything else

## Status

- [ ] Lexer (llex.c/.h) -> [lex.zig](src/lex.zig)
  + [x] Keywords
  + [x] Identifiers
  + [x] `..`, `...`
  + [x] `==`, `>=`, `<=`, `~=`
  + [x] String literals (single/double quoted and multi-line (`[[`))
  + [x] Comments (`--` and `--[[`)
  + [x] Numbers
  + [x] Improve tests, perhaps use fuzz testing
    - See [Fuzzing As a Test Case Generator](https://www.ryanliptak.com/blog/fuzzing-as-test-case-generator/) and [squeek502/fuzzing-lua](https://github.com/squeek502/fuzzing-lua/)
  + [ ] Cleanup implementation
- [x] String parsing (in Lua this was done at lex-time) -> [parse_literal.zig](src/parse_literal.zig) (see [`4324bd0`](https://github.com/squeek502/zua/commit/5de41fdf71eaf2a0b235e5eb581072d5488a1c57) for more details)
- [ ] Number parsing (in Lua this was done at lex-time) -> [parse_literal.zig](src/parse_literal.zig)
  + [x] Basic number parsing
  + [ ] Proper `strtod`-compatible number parsing implementation
- [ ] Parser (lparser.c/.h) -> [parse.zig](src/parse.zig)
- [ ] ...

## Why Lua 5.1?

It's what I'm most familiar with, and I'm also assuming that 5.1 is simpler internally than more recent Lua versions.

## Building / running

- `zig build` to build zua.exe
- `zig build test` to build & run all tests
- `zig build run` to build & run zua.exe (does nothing right now)
- `zig build fuzz_lex` to run lexer tests on a large set of inputs/outputs generated by [fuzzing-lua](https://github.com/squeek502/fuzzing-lua)
- `zig build bench_lex` to run a benchmark of the lexer (this benchmark needs improvement)
- `zig build fuzz_strings` to run string parsing tests on a set of inputs/outputs generated by [fuzzing-lua](https://github.com/squeek502/fuzzing-lua)
