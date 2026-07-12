# Z-Set

[![Zig Version](https://img.shields.io/badge/zig-0.16-orange.svg)](https://ziglang.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Generic, insertion-ordered, ECMAScript-compatible **Set** implementation in Zig 0.16, part of the [z-*](https://github.com/carlos-sweb) micro-library ecosystem.

## Design

`ZSet(T)` is a thin wrapper over [z-map](https://github.com/carlos-sweb/z-map)'s `ZMap(T, void)` — reuses its array-backed storage, SameValueZero comparison, and insertion-order iteration instead of duplicating that plumbing. Adding a value already present (per SameValueZero) is a no-op and does not move its position.

## API

| Method | ECMAScript Equivalent |
|---|---|
| `add(value)` | `Set.prototype.add()` |
| `has(value)` | `Set.prototype.has()` |
| `delete(value)` | `Set.prototype.delete()` — ordered; re-adding a deleted value moves it to the end |
| `clear()` | `Set.prototype.clear()` |
| `size()` | `Set.prototype.size` |
| `values()` | `Set.prototype.values()` (and its aliases `keys()`/`[Symbol.iterator]`) |
| `entries(allocator)` | `Set.prototype.entries()` — `[value, value]` pairs, for shape parity with `Map` |
| `forEach(context, callback)` | `Set.prototype.forEach()` |
| `fromSlice(allocator, values)` | construct from a slice, deduplicating by SameValueZero |

## Testing

```bash
zig build test
```

## License

MIT
