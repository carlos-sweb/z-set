# Z-Set

[![Zig Version](https://img.shields.io/badge/zig-0.17-orange.svg)](https://ziglang.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Generic, insertion-ordered, ECMAScript-compatible **Set** implementation in Zig 0.17, part of the [z-*](https://github.com/carlos-sweb) micro-library ecosystem.

## Design

`ZSet(T)` is a thin wrapper over [z-map](https://github.com/carlos-sweb/z-map)'s `ZMap(T, void)` — reuses its array-backed storage, SameValueZero comparison, and insertion-order iteration instead of duplicating that plumbing. Adding a value already present (per SameValueZero) is a no-op and does not move its position.

## API

[Browse the generated Zig API documentation](https://carlos-sweb.github.io/z-set/).

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

## Compatibility

Release `0.1.0` is compatible with **Zig 0.17.0**. The build fetches
[z-map `0.1.0`](https://github.com/carlos-sweb/z-map/releases/tag/0.1.0)
by URL with a pinned package hash.

## Testing

```bash
zig build test
```

## Documentation

Generate the API reference from the source doc comments:

```bash
zig build docs
```

The output is written to `zig-out/docs/`. GitHub Pages serves the generated
reference from `docs/` on the `master` branch. To refresh the published files:

```bash
mkdir -p docs
cp -a zig-out/docs/. docs/
touch docs/.nojekyll
```

## License

MIT
