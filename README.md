# purescript-go-package-sets

Package sets for PureScript on Go. Point your `spago.yaml` at one and the Go bindings, the gRPC
and HTTP libraries and the registry packages that work on Go are all there, at versions that build
together. No `extraPackages` lists.

It's what [purerl's package sets](https://github.com/purerl/package-sets) are for Erlang, for
[googoo](https://github.com/i-am-the-slime/iris-go-backend), the PureScript compiler with a Go
backend.

## Using it

```yaml
package:
  name: hello
  dependencies:
    - effect
    - go-io
    - prelude
workspace:
  packageSet:
    url: https://raw.githubusercontent.com/rowtype-yoga/purescript-go-package-sets/go-0.1.18-20261126.8/packages.json
```

```purescript
module Main where

import Prelude

import Effect (Effect)
import Go.IO (launchIO_)
import Go.IO.Console (log)

main :: Effect Unit
main = launchIO_ do
  log "hello from Go"
```

```
$ googoo run --go
hello from Go
```

You need googoo 0.1.18-go.5 or newer, Go 1.27 and Spago 1.0:

```bash
brew install spago i-am-the-slime/tap/googoo
```

`googoo go` builds the binary without running it and prints where it put it.

## What's in it

| | Packages |
| --- | --- |
| Go's standard library, from [purescript-go](https://github.com/i-am-the-slime/purescript-go) `v0.3.0` | `go-io`, `go-os`, `go-exec`, `go-http`, `go-time`, `go-bytes` |
| [yoga-protobuf](https://github.com/rowtype-yoga/purescript-yoga-protobuf) `v0.2.0` | `yoga-protobuf` |
| [yoga-go-http-om](https://github.com/rowtype-yoga/purescript-yoga-go-http-om) `v0.2.0` | `yoga-go-http-om` |
| [yoga-om-layer](https://github.com/rowtype-yoga/purescript-yoga-om-layer) `v2.2.0` | `yoga-om-layer` |
| [yoga-postgres](https://github.com/rowtype-yoga/purescript-yoga-postgres) `v0.4.0`, [yoga-postgres-om](https://github.com/rowtype-yoga/purescript-yoga-postgres-om) `v0.2.0` and [yoga-sql-types](https://github.com/rowtype-yoga/purescript-yoga-sql-types) `v0.3.0`, Postgres on pgx | `yoga-postgres`, `yoga-postgres-io`, `yoga-postgres-om`, `yoga-postgres-omio`, `yoga-sql-types` |
| [yoga-connect](https://github.com/rowtype-yoga/purescript-yoga-connect) `v0.3.2` | `yoga-connect`, `yoga-connect-go`, `yoga-strom-io` |
| [Bubble Tea](https://github.com/i-am-the-slime/purescript-bubbletea) `v0.3.0`, [Bubbles](https://github.com/i-am-the-slime/purescript-bubbles), [Huh](https://github.com/i-am-the-slime/purescript-huh), [Lip Gloss](https://github.com/i-am-the-slime/purescript-lipgloss), [Harmonica](https://github.com/i-am-the-slime/purescript-harmonica) and [Glamour](https://github.com/i-am-the-slime/purescript-glamour) `v0.2.0` | `bubbletea`, `bubbles`, `huh`, `lipgloss`, `harmonica`, `glamour` |
| The registry, from its package set `80.8.1` | `prelude`, `effect`, `aff`, `avar`, `arrays`, `strings`, `ordered-collections`, `unordered-collections`, `foreign-object`, `refs`, `st`, `transformers`, `variant`, `record`, `datetime`, `now`, `int64`, `yoga-json`, `yoga-om`, `spec`, `uuid` and what they need: 79 packages |

`packages.json` has the full list with versions. A set never changes once it's tagged, a new one
gets a new tag.

## Tags

`go-<googoo version>-<date>`, like purerl's `erl-<purs version>-<date>`. The googoo version is
the oldest one the set was checked with, newer ones work too. A second set on the same day gets a
`.1`, a third a `.2`.

| Tag | googoo | Registry set | What changed |
| --- | --- | --- | --- |
| `go-0.1.18-20261126.8` | 0.1.18-go.6 | 80.8.1 | yoga-connect `v0.3.2`: compiles with purs and runs on JavaScript, enums work there, and protoc reads the `.proto` of a method whose message has its name |
| `go-0.1.18-20261126.7` | 0.1.18-go.6 | 80.8.1 | yoga-connect `v0.3.1`: a bidi call reaches the server before the client has sent anything |
| `go-0.1.18-20261126.6` | 0.1.18-go.5 | 80.8.1 | yoga-connect `v0.3.0`: gRPC services as PureScript types, with their protocol buffer codecs and `.proto` worked out from them |
| `go-0.1.18-20261126.5` | 0.1.18-go.5 | 80.8.1 | Postgres: yoga-postgres `v0.4.0` with yoga-postgres-io, yoga-postgres-om `v0.2.0` with yoga-postgres-omio, yoga-sql-types `v0.3.0`; uuid |
| `go-0.1.18-20261126.4` | 0.1.18-go.5 | 80.8.1 | yoga-om-layer `v2.2.0`, which runs on Go |
| `go-0.1.18-20261126.3` | 0.1.18-go.5 | 80.8.1 | `Int` is Go's `int` in every Go binding (purescript-go `v0.3.0`, Bubble Tea `v0.3.0`, the rest `v0.2.0`); Harmonica and Glamour |
| `go-0.1.18-20261126.2` | 0.1.18-go.4 | 80.8.1 | checked with googoo 0.1.18-go.4, the same packages as before |
| `go-0.1.18-20261126.1` | 0.1.18-go.3 | 80.8.1 | Bubble Tea, Bubbles, Huh and Lip Gloss for terminal UIs |
| `go-0.1.18-20261126` | 0.1.18-go.3 | 80.8.1 | checked with googoo 0.1.18-go.3, the release that renamed `iris` to `googoo` |
| `go-0.1.18-20261125.1` | 0.1.18-go.2 | 80.8.1 | yoga-go-http-om `v0.1.2`, which takes yoga-om 2.x |
| `go-0.1.18-20261125` | 0.1.18-go.2 | 80.8.1 | the first set |

Switching sets is changing the tag in the URL.

## Adding a package

Open a pull request with:

1. The package in `packages.json`. From the registry it's just the version:

   ```json
   "variant": "8.0.0"
   ```

   From git it's the repository, a tag, the folder in it if there's more than one package, and
   what it depends on, as its `spago.yaml` says:

   ```json
   "go-io": {
     "git": "https://github.com/i-am-the-slime/purescript-go.git",
     "ref": "v0.2.0",
     "subdir": "packages/go-io",
     "dependencies": ["aff", "arrays", "console", "..."]
   }
   ```

2. For a package from git, a check in `verify/<package>/`: a `spago.yaml` for a package called
   `verify-<package>` with a `run.main`, a small program in `src/` that uses the package, and an
   `expected.txt` with exactly what the program prints. `verify/go-io` is a good one to copy.
   A registry package that needs Go to prove itself can get a line in `verify/base` instead.

3. A run of the checks:

   ```bash
   gogogo scripts/verify.purs
   ```

   or with googoo alone:

   ```bash
   googoo run --go -p verify-runner
   ```

## The checks

`scripts/verify.purs` makes a fresh project in a temporary folder that gets its packages from the
set and nowhere else. In it:

- every registry package compiles (`googoo build` of a package that depends on all of them),
- every package in `verify/` compiles to Go, runs, and prints exactly its `expected.txt`,
- and every package that comes from git has such a check.

CI has no database, so the Postgres checks point their pool at a port nothing listens on: they
prove a typed query program compiles, links pgx and fails the way it should. The libraries' own
specs run against a real Postgres.

```
ok    registry packages compile
ok    base on Go
ok    go-bytes on Go
...
ok    yoga-connect-go on Go
Every check passed.
```

Give it a URL to check a set that's already published:

```bash
gogogo scripts/verify.purs https://raw.githubusercontent.com/rowtype-yoga/purescript-go-package-sets/go-0.1.18-20261126.8/packages.json
```

`IRIS` picks another googoo binary. CI runs the checks on every push and tag, with the released
googoo the tag is named after.
