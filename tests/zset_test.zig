const std = @import("std");
const testing = std.testing;
const ZSet = @import("zset").ZSet;

test "add/has/delete/size basic behavior" {
    var set = ZSet(i32).init(testing.allocator);
    defer set.deinit();

    try set.add(1);
    try set.add(2);
    try testing.expectEqual(@as(usize, 2), set.size());
    try testing.expect(set.has(1));
    try testing.expect(!set.has(3));

    try testing.expect(set.delete(1));
    try testing.expect(!set.delete(1));
    try testing.expectEqual(@as(usize, 1), set.size());
}

test "adding the same value twice does not duplicate it or move it" {
    var set = ZSet(i32).init(testing.allocator);
    defer set.deinit();

    try set.add(1);
    try set.add(2);
    try set.add(1); // no-op: already present

    try testing.expectEqual(@as(usize, 2), set.size());
    try testing.expectEqualSlices(i32, &[_]i32{ 1, 2 }, set.values());
}

test "values() preserves insertion order; delete()+add() moves to the end" {
    var set = ZSet(i32).init(testing.allocator);
    defer set.deinit();

    try set.add(3);
    try set.add(1);
    try set.add(2);
    try testing.expectEqualSlices(i32, &[_]i32{ 3, 1, 2 }, set.values());

    try testing.expect(set.delete(3));
    try set.add(3);
    try testing.expectEqualSlices(i32, &[_]i32{ 1, 2, 3 }, set.values());
}

test "SameValueZero: NaN can only be added once, +0/-0 are the same value" {
    var set = ZSet(f64).init(testing.allocator);
    defer set.deinit();

    try set.add(std.math.nan(f64));
    try set.add(std.math.nan(f64)); // a different NaN bit-pattern-equivalent value
    try testing.expectEqual(@as(usize, 1), set.size());

    try set.add(0.0);
    try set.add(-0.0);
    try testing.expectEqual(@as(usize, 2), set.size());
}

test "entries() yields [value, value] pairs, matching Map's shape" {
    var set = ZSet(i32).init(testing.allocator);
    defer set.deinit();
    try set.add(10);
    try set.add(20);

    const es = try set.entries(testing.allocator);
    defer testing.allocator.free(es);

    try testing.expectEqual(@as(i32, 10), es[0].key);
    try testing.expectEqual(@as(i32, 10), es[0].value);
    try testing.expectEqual(@as(i32, 20), es[1].key);
    try testing.expectEqual(@as(i32, 20), es[1].value);
}

test "forEach visits values in insertion order" {
    var set = ZSet(i32).init(testing.allocator);
    defer set.deinit();
    try set.add(3);
    try set.add(1);
    try set.add(2);

    var visited: std.ArrayList(i32) = .empty;
    defer visited.deinit(testing.allocator);
    set.forEach(&visited, struct {
        fn callback(ctx: *std.ArrayList(i32), value: i32) void {
            ctx.append(testing.allocator, value) catch unreachable;
        }
    }.callback);

    try testing.expectEqualSlices(i32, &[_]i32{ 3, 1, 2 }, visited.items);
}

test "fromSlice deduplicates by SameValueZero" {
    var set = try ZSet(i32).fromSlice(testing.allocator, &[_]i32{ 1, 2, 1, 3, 2 });
    defer set.deinit();

    try testing.expectEqual(@as(usize, 3), set.size());
    try testing.expectEqualSlices(i32, &[_]i32{ 1, 2, 3 }, set.values());
}

test "ZSet with []const u8 values compares by content, not pointer identity" {
    var set = ZSet([]const u8).init(testing.allocator);
    defer set.deinit();

    try set.add("hello");

    var buf: [5]u8 = .{ 'h', 'e', 'l', 'l', 'o' };
    try testing.expect(set.has(buf[0..]));
}

test "clear() empties the set" {
    var set = ZSet(i32).init(testing.allocator);
    defer set.deinit();
    try set.add(1);
    set.clear();
    try testing.expectEqual(@as(usize, 0), set.size());
}
