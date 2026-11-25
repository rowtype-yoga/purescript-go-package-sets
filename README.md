# purescript-go-package-sets

Package sets for PureScript on Go. Point your `spago.yaml` at one and the Go bindings, the gRPC
and HTTP libraries and the registry packages that work on Go are all there, at versions that build
together. No `extraPackages` lists.

It's what [purerl's package sets](https://github.com/purerl/package-sets) are for Erlang, for
[Iris](https://github.com/i-am-the-slime/iris-go-backend)'s Go backend.

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
    url: https://raw.githubusercontent.com/rowtype-yoga/purescript-go-package-sets/go-0.1.18-20261125/packages.json
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
$ iris run --go
hello from Go
```

You need Iris 0.1.18-go.2 or newer, Go 1.27 and Spago 1.0:

```bash
brew install spago i-am-the-slime/tap/iris
```

`iris go` builds the binary without running it and prints where it put it.

## What's in it

| | Packages |
| --- | --- |
| Go's standard library, from [purescript-go](https://github.com/i-am-the-slime/purescript-go) `v0.2.0` | `go-io`, `go-os`, `go-exec`, `go-http`, `go-time`, `go-bytes` |
| [yoga-protobuf](https://github.com/rowtype-yoga/purescript-yoga-protobuf) `v0.1.0` | `yoga-protobuf` |
| [yoga-go-http-om](https://github.com/rowtype-yoga/purescript-yoga-go-http-om) `v0.1.1` | `yoga-go-http-om` |
| [yoga-connect](https://github.com/rowtype-yoga/purescript-yoga-connect) `v0.1.1` | `yoga-connect`, `yoga-connect-go`, `yoga-strom-io` |
| The registry, from its package set `80.8.1` | `prelude`, `effect`, `aff`, `avar`, `arrays`, `strings`, `ordered-collections`, `unordered-collections`, `foreign-object`, `refs`, `st`, `transformers`, `variant`, `record`, `datetime`, `now`, `int64`, `yoga-json`, `yoga-om`, `spec` and what they need: 79 packages |

`packages.json` has the full list with versions. A set never changes once it's tagged, a new one
gets a new tag.

## Tags

`go-<Iris version>-<date>`, like purerl's `erl-<purs version>-<date>`. The Iris version is the
oldest one the set was checked with, newer ones work too.

| Tag | Iris | Registry set |
| --- | --- | --- |
| `go-0.1.18-20261125` | 0.1.18-go.2 | 80.8.1 |

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

   or with Iris alone:

   ```bash
   iris run --go -p verify-runner
   ```

## The checks

`scripts/verify.purs` makes a fresh project in a temporary folder that gets its packages from the
set and nowhere else. In it:

- every registry package compiles (`iris build` of a package that depends on all of them),
- every package in `verify/` compiles to Go, runs, and prints exactly its `expected.txt`,
- and every package that comes from git has such a check.

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
gogogo scripts/verify.purs https://raw.githubusercontent.com/rowtype-yoga/purescript-go-package-sets/go-0.1.18-20261125/packages.json
```

`IRIS` picks another iris binary. CI runs the checks on every push and tag, with the released
Iris the tag is named after.
