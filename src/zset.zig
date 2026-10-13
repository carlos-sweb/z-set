//! Insertion-ordered sets with ECMAScript SameValueZero value comparison.
//! Allocate a `ZSet(T)` with `init`, add values with `add`, and release its
//! storage with `deinit`. Values themselves remain owned by the caller.

const std = @import("std");
const Allocator = std.mem.Allocator;
const zmap = @import("zmap");

/// Generic ECMAScript-compatible Set implementation. Thin wrapper over
/// ZMap(T, void) — reuses its array-backed storage, SameValueZero context,
/// and insertion-order iteration instead of duplicating that plumbing.
/// `T` is the value type. Strings compare by content; NaNs compare equal,
/// and positive and negative zero are treated as the same value.
pub fn ZSet(comptime T: type) type {
    return struct {
        const Self = @This();

        map: zmap.ZMap(T, void),

        /// Create an empty set whose storage uses `allocator`.
        pub fn init(allocator: Allocator) Self {
            return .{ .map = zmap.ZMap(T, void).init(allocator) };
        }

        /// Release set storage. Does not free resources owned by its values.
        pub fn deinit(self: *Self) void {
            self.map.deinit();
        }

        /// Set.prototype.add() - adding a value already present is a no-op
        /// (SameValueZero) and does not move its position.
        /// Returns `error.OutOfMemory` if storage cannot grow.
        pub fn add(self: *Self, value: T) !void {
            try self.map.set(value, {});
        }

        /// Return whether `value` is present, using SameValueZero comparison.
        pub fn has(self: *const Self, value: T) bool {
            return self.map.has(value);
        }

        /// Set.prototype.delete() - ordered, same semantics as ZMap.delete().
        /// Return whether `value` was removed; preserve remaining value order.
        pub fn delete(self: *Self, value: T) bool {
            return self.map.delete(value);
        }

        /// Remove all values while retaining storage for reuse.
        pub fn clear(self: *Self) void {
            self.map.clear();
        }

        /// Return the number of distinct values in the set.
        pub fn size(self: *const Self) usize {
            return self.map.size();
        }

        /// Set.prototype.values() (and its aliases keys()/[Symbol.iterator])
        /// - insertion order.
        /// The returned slice borrows set storage and may be invalidated by
        /// mutation or `deinit`. Do not modify it directly.
        pub fn values(self: *const Self) []T {
            return self.map.keys();
        }

        /// A pair containing the same set value in both fields.
        pub const Entry = struct { key: T, value: T };

        /// Set.prototype.entries() - [value, value] pairs, for shape parity
        /// with Map.prototype.entries() (per spec). Caller frees the
        /// returned slice with `allocator`.
        /// Returns `error.OutOfMemory` if the slice cannot be allocated.
        pub fn entries(self: *const Self, allocator: Allocator) ![]Entry {
            const vs = self.map.keys();
            const list = try allocator.alloc(Entry, vs.len);
            for (vs, 0..) |v, i| list[i] = .{ .key = v, .value = v };
            return list;
        }

        /// Set.prototype.forEach() - insertion order.
        /// Call `callback(context, value)` for each value. The callback must
        /// not mutate this set while iteration is in progress.
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
        /// Returns `error.OutOfMemory` on allocation failure and releases
        /// any partially constructed storage before returning the error.
        pub fn fromSlice(allocator: Allocator, values_in: []const T) !Self {
            var set = Self.init(allocator);
            errdefer set.deinit();
            for (values_in) |v| try set.add(v);
            return set;
        }
    };
}
