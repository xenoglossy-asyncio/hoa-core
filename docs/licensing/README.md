# Licensing and repository layout

This page records the license audit and the proposed monorepo/submodule layout. It is engineering
documentation, not legal advice; a final distribution should be reviewed by counsel.

## What is actually in the tree

| Path | License | Notes |
| --- | --- | --- |
| `server/` | GPL-2.0 | VMaNGOS fork. `server/LICENSE` is GPL-2.0. 736 of the 815 GPL source headers say "either version 2 ... or later". The bundled Windows MySQL client headers in `server/dep/windows/include/mysql` are GPL-2.0 (version 2 only), and the bundled OpenSSL 1.0.2 carries the OpenSSL/SSLeay license, which the FSF treats as GPL-incompatible. gSOAP and libmpq are GPL-2.0-or-later; recastnavigation is zlib; cpptrace is MIT; utf8cpp is Boost; g3dlite contains BSD/LGPL parts. |
| `client/` | MIT OR Apache-2.0 | benilla fork; every workspace crate declares `MIT OR Apache-2.0`. Cargo dependencies are MIT, Apache-2.0, MPL-2.0, zlib, BSD and similar (the generated `CLIENT-LICENSES.md` lists them per release). |
| `addon/`, `glue/`, `launcher/`, `config/`, `localization/` | GPL-3.0 | Hordes of Azeroth derivatives. The launcher's Avalonia and Mono.Nat packages are MIT. |
| `shared/`, `scripts/`, `docs/`, new `tools/` | GPL-2.0-or-later | This repository's own code. |
| Addon fonts | OFL-1.1 | Barlow, Noto Sans SC, Noto Sans TC; license files beside the fonts. |
| MariaDB Server / world DB | GPL-2.0 | Downloaded or shipped separately; not linked into our binaries. |

## Compatibility

- GPL-3.0 combines fine with MIT, Apache-2.0, BSD, zlib, Boost and LGPL.
- GPL-3.0 cannot be combined into one work with GPL-2.0-only code. GPLv2 and GPLv3 programs can
  still be **aggregated** on one medium (client, server, launcher, addon) as separate programs.
- The shipped server binary is constrained by the GPL-2.0-only MySQL client and by OpenSSL 1.0.2;
  it should be distributed as GPL-2.0 unless those are replaced.
- MIT cannot be the license of the repository as a whole: the addon, Glue and launcher are GPL-3.0
  derivatives. MIT can only cover original, standalone code.

**Decision (2026-11-06):** the repository's original code is **GPL-3.0**; `shared/` and
`shared/content` stay **GPL-2.0-or-later** because the GPL-2.0 server and the GPL-3.0 addon both
use them; the server stays **GPL-2.0**, the client stays **MIT OR Apache-2.0**, and the addon,
Glue, launcher, config and localization stay **GPL-3.0**.

**The repository stays a monorepo and does not use submodules.** A license is satisfied by
keeping its text and copyright notices, naming the source and the local modifications, and
providing the corresponding source; Git structure is not a license requirement. Submodules are
only an optional upstream-tracking tool and would make contributions, atomic cross-directory
changes, CI and Gitee mirroring harder. Each imported directory keeps its `LICENSE` and
`UPSTREAM.md`; `LICENSE-NOTICE.md` and `provenance.yaml` record the rest, and a release tag is the
corresponding source.

## Proposed layout

```
hoa-core                     GPL-3.0 (top-level LICENSE for original code)
  LICENSES/                  GPL-2.0, GPL-3.0, MIT, Apache-2.0, OFL-1.1 texts
  shared/                    GPL-2.0-or-later (used by the server and the addon)
  server/                    GPL-2.0 + LICENSE + UPSTREAM.md
  client/                    MIT OR Apache-2.0 + LICENSE-MIT/LICENSE-APACHE + UPSTREAM.md
  addon/ glue/ launcher/     GPL-3.0 + UPSTREAM.md
  config/ localization/      GPL-3.0 + UPSTREAM.md
  tools/ docs/ scripts/      GPL-3.0 original code (imported tools keep their notices)
```

If upstream tracking ever becomes painful, `server/` and `client/` can become submodules of their
own fork repositories; that is a maintenance choice, not a licensing one. In that case use relative
URLs (`../hoa-server.git`) so GitHub and Gitee clones resolve on the same host, mirror the fork
repositories, and update the release tooling first: `git archive` does not include submodule
content.

## Steps

1. Keep the top-level `LICENSE` (GPL-3.0) and the per-directory licenses; the decision above is
   recorded here and in `LICENSE-NOTICE.md`.
2. Keep a `LICENSE`/`LICENSE-MIT`/`LICENSE-APACHE` and an `UPSTREAM.md` in every imported
   directory, with the upstream URL, commit, base and local changes.
3. Keep `LICENSES/` with the full texts and `THIRD-PARTY-NOTICES.md` for dependencies.
4. For a GPL-3.0 server, replace the GPL-2.0-only MySQL client and the OpenSSL 1.0.2 bundle with
   compatible dependencies; otherwise keep the server GPL-2.0 as a separate program.
5. Do not relicense a GPL-2.0-only part as GPL-3.0 or MIT. If submodules are introduced later,
   update CI (`submodules: recursive`) and release packaging in the same change.
