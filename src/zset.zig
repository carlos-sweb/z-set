const std = @import("std");
const Allocator = std.mem.Allocator;
const zmap = @import("zmap");

/// Generic ECMAScript-compatible Set implementation. Thin wrapper over
/// ZMap(T, void) — reuses its array-backed storage, SameValueZero context,
/// and insertion-order iteration instead of duplicating that plumbing.
pub fn ZSet(comptime T: type) type {
    return struct {
        const Self = @This();

        map: zmap.ZMap(T, void),

        pub fn init(allocator: Allocator) Self {
            return .{ .map = zmap.ZMap(T, void).init(allocator) };
        }

        pub fn deinit(self: *Self) void {
            self.map.deinit();
        }

        /// Set.prototype.add() - adding a value already present is a no-op
        /// (SameValueZero) and does not move its position.
        pub fn add(self: *Self, value: T) !void {
            try self.map.set(value, {});
        }

        pub fn has(self: *const Self, value: T) bool {
            return self.map.has(value);
        }

        /// Set.prototype.delete() - ordered, same semantics as ZMap.delete().
        pub fn delete(self: *Self, value: T) bool {
            return self.map.delete(value);
        }

        pub fn clear(self: *Self) void {
            self.map.clear();
        }

        pub fn size(self: *const Self) usize {
            return self.map.size();
        }

        /// Set.prototype.values() (and its aliases keys()/[Symbol.iterator])
        /// - insertion order.
        pub fn values(self: *const Self) []T {
            return self.map.keys();
        }

        pub const Entry = struct { key: T, value: T };

        /// Set.prototype.entries() - [value, value] pairs, for shape parity
        /// with Map.prototype.entries() (per spec). Caller frees the
        /// returned slice with `allocator`.
        pub fn entries(self: *const Self, allocator: Allocator) ![]Entry {
            const vs = self.map.keys();
            const list = try allocator.alloc(Entry, vs.len);
            for (vs, 0..) |v, i| list[i] = .{ .key = v, .value = v };
            return list;
        }

        /// Set.prototype.forEach() - insertion order.
        pub fn forEach(
            self: *const Self,
            context: anytype,
            comptime callback: fn (@TypeOf(context), T) void,
        ) void {
            for (self.map.keys()) |v| callback(context, v);
        }

        /// Build a ZSet from a slice of values, in order, deduplicated by
        /// SameValueZero (later duplicates are no-ops, matching `new
        /// Set([...])` semantics).
        pub fn fromSlice(allocator: Allocator, values_in: []const T) !Self {
            var set = Self.init(allocator);
            errdefer set.deinit();
            for (values_in) |v| try set.add(v);
            return set;
        }
    };
}
