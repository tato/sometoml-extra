const std = @import("std");
const toml = @import("toml");

var allocator: std.mem.Allocator = undefined;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    allocator = arena.allocator();

    const stdin = std.io.getStdIn();
    const stdout = std.io.getStdOut();
    var buffered_stdout = std.io.bufferedWriter(stdout.writer());

    const table = try toml.parse(stdin.reader(), .{ .allocator = allocator });
    try std.json.stringify(FmtTable{ .table = table }, .{}, buffered_stdout.writer());
}

const FmtTable = struct {
    table: toml.Table,
    pub fn jsonStringify(
        value: FmtTable,
        options: std.json.StringifyOptions,
        out_stream: anytype,
    ) !void {
        try out_stream.writeAll("{");

        var index = value.table.table.count();

        var i = value.table.table.iterator();
        while (i.next()) |entry| {
            try std.json.stringify(entry.key_ptr.*, options, out_stream);
            try out_stream.writeAll(":");
            try std.json.stringify(FmtValue{ .value = entry.value_ptr.* }, options, out_stream);
            index -= 1;
            if (index != 0) try out_stream.writeAll(",");
        }

        try out_stream.writeAll("}");
    }
};

const FmtValue = struct {
    value: toml.Value,

    pub fn jsonStringify(
        value: FmtValue,
        options: std.json.StringifyOptions,
        out_stream: anytype,
    ) !void {
        switch (value.value) {
            .table => |t| try std.json.stringify(FmtTable{ .table = t }, options, out_stream),
            .array => |a| {
                try out_stream.writeAll("[");
                for (a.items) |elem, i| {
                    try std.json.stringify(FmtValue{ .value = elem }, options, out_stream);
                    if (i != a.items.len - 1) try out_stream.writeAll(",");
                }
                try out_stream.writeAll("]");
            },
            .string => |v| {
                const fun = FunnyValue{ .@"type" = "string", .value = v };
                try std.json.stringify(fun, options, out_stream);
            },
            .integer => {
                const v = std.fmt.allocPrint(allocator, "{}", .{value.value}) catch unreachable;
                const fun = FunnyValue{ .@"type" = "integer", .value = v };
                try std.json.stringify(fun, options, out_stream);
            },
            .float => {
                const v = std.fmt.allocPrint(allocator, "{}", .{value.value}) catch unreachable;
                const fun = FunnyValue{ .@"type" = "float", .value = v };
                try std.json.stringify(fun, options, out_stream);
            },
            .boolean => {
                const v = std.fmt.allocPrint(allocator, "{}", .{value.value}) catch unreachable;
                const fun = FunnyValue{ .@"type" = "bool", .value = v };
                try std.json.stringify(fun, options, out_stream);
            },
            .offset_datetime => {
                const v = std.fmt.allocPrint(allocator, "{}", .{value.value}) catch unreachable;
                const fun = FunnyValue{ .@"type" = "datetime", .value = v };
                try std.json.stringify(fun, options, out_stream);
            },
            .local_datetime => {
                const v = std.fmt.allocPrint(allocator, "{}", .{value.value}) catch unreachable;
                const fun = FunnyValue{ .@"type" = "datetime-local", .value = v };
                try std.json.stringify(fun, options, out_stream);
            },
            .local_date => {
                const v = std.fmt.allocPrint(allocator, "{}", .{value.value}) catch unreachable;
                const fun = FunnyValue{ .@"type" = "date-local", .value = v };
                try std.json.stringify(fun, options, out_stream);
            },
            .local_time => {
                const v = std.fmt.allocPrint(allocator, "{}", .{value.value}) catch unreachable;
                const fun = FunnyValue{ .@"type" = "time-local", .value = v };
                try std.json.stringify(fun, options, out_stream);
            },
        }
    }
};

const FunnyValue = struct {
    @"type": []const u8,
    value: []const u8,
};
