const std = @import("std");
const Allocator = std.mem.Allocator;
const Token = @import("lex.zig").Token;

pub const Tree = struct {
    node: *Node,

    /// not owned by the tree
    source: []const u8,

    arena: std.heap.ArenaAllocator.State,
    allocator: *Allocator,

    pub fn deinit(self: *Tree) void {
        self.arena.promote(self.allocator).deinit();
    }

    pub fn dump(self: *Tree, writer: anytype) @TypeOf(writer).Error!void {
        try self.node.dump(writer, 0);
    }
};

pub const Node = struct {
    id: Id,

    pub const Id = enum {
        chunk,
        call,
        literal,
        identifier,
        local_statement,
        field_access,
        index_access,

        pub fn Type(id: Id) type {
            return switch (id) {
                .chunk => Chunk,
                .call => Call,
                .literal => Literal,
                .identifier => Identifier,
                .local_statement => LocalStatement,
                .field_access => FieldAccess,
                .index_access => IndexAccess,
            };
        }
    };

    pub fn cast(base: *Node, comptime id: Id) ?*id.Type() {
        if (base.id == id) {
            return @fieldParentPtr(id.Type(), "base", base);
        }
        return null;
    }

    pub const Chunk = struct {
        base: Node = .{ .id = .chunk },
        body: []*Node,
    };

    pub const Call = struct {
        base: Node = .{ .id = .call },
        expression: *Node,
        arguments: []*Node,
    };

    pub const Literal = struct {
        base: Node = .{ .id = .literal },
        token: Token,
    };

    pub const Identifier = struct {
        base: Node = .{ .id = .identifier },
        token: Token,
    };

    pub const LocalStatement = struct {
        base: Node = .{ .id = .local_statement },
        names: []Token,
        values: []*Node,
    };

    pub const FieldAccess = struct {
        base: Node = .{ .id = .field_access },
        prefix: *Node,
        field: Token,
        separator: Token,
    };

    pub const IndexAccess = struct {
        base: Node = .{ .id = .index_access },
        prefix: *Node,
        index: *Node,
    };

    pub fn dump(
        node: *const Node,
        writer: anytype,
        indent: usize,
    ) @TypeOf(writer).Error!void {
        try writer.writeByteNTimes(' ', indent);
        try writer.writeAll(@tagName(node.id));
        switch (node.id) {
            .chunk => {
                try writer.writeAll("\n");
                const chunk = @fieldParentPtr(Node.Chunk, "base", node);
                for (chunk.body) |body_node| {
                    try body_node.dump(writer, indent + 1);
                }
            },
            .call => {
                try writer.writeAll("\n");
                const call = @fieldParentPtr(Node.Call, "base", node);
                try call.expression.dump(writer, indent + 1);
                try writer.writeByteNTimes(' ', indent + 1);
                try writer.writeAll("(");
                if (call.arguments.len > 0) {
                    try writer.writeAll("\n");
                    for (call.arguments) |arg_node| {
                        try arg_node.dump(writer, indent + 2);
                    }
                    try writer.writeByteNTimes(' ', indent + 1);
                }
                try writer.writeAll(")\n");
            },
            .identifier => {
                try writer.writeAll("\n");
            },
            .literal => {
                const literal = @fieldParentPtr(Node.Literal, "base", node);
                try writer.writeAll(" ");
                try writer.writeAll(literal.token.nameForDisplay());
                try writer.writeAll("\n");
            },
            .local_statement => {
                const local = @fieldParentPtr(Node.LocalStatement, "base", node);
                for (local.names) |name_token| {
                    try writer.writeAll(" ");
                    try writer.writeAll(name_token.nameForDisplay());
                }
                if (local.values.len > 0) {
                    try writer.writeAll(" =\n");
                    for (local.values) |value_node| {
                        try value_node.dump(writer, indent + 1);
                    }
                } else {
                    try writer.writeAll("\n");
                }
            },
            .field_access => {
                const field_access = @fieldParentPtr(Node.FieldAccess, "base", node);
                try writer.writeAll(" ");
                try writer.writeAll(field_access.separator.nameForDisplay());
                try writer.writeAll(field_access.field.nameForDisplay());
                try writer.writeAll("\n");
                try field_access.prefix.dump(writer, indent + 1);
            },
            .index_access => {
                const index_access = @fieldParentPtr(Node.IndexAccess, "base", node);
                try writer.writeAll("\n");
                try index_access.prefix.dump(writer, indent + 1);
                try index_access.index.dump(writer, indent + 1);
            },
        }
    }
};
