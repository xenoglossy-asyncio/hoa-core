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

**Recommendation:** license the repository's original code under **GPL-3.0**, keep the addon,
Glue, launcher and config under GPL-3.0, keep the server as a separate GPL-2.0 program, and keep
the client under MIT/Apache-2.0. If the server must also be GPL-3.0, replace the bundled MySQL
client with MariaDB Connector/C (LGPL-2.1) and OpenSSL 1.0.2 with OpenSSL 3 (Apache-2.0) or another
compatible TLS library; the VMaNGOS core headers are already "or later".

MIT for the top-level repository is possible only if the GPL parts stay in separate submodules and
the top-level repository contains just original MIT code. That is a valid mixed-license aggregate,
but users must not read the top-level MIT as covering the game.

## Proposed layout

```
hoa-core                     GPL-3.0 (original code + GPL-3.0 directories)
  shared/ tools/ docs/ scripts/ config/
  addon/ glue/ launcher/      (GPL-3.0; can stay in the monorepo)
  server/ -> submodule hoa-server   GPL-2.0-or-later / GPL-2.0 as shipped
  client/ -> submodule hoa-client   MIT OR Apache-2.0
```

Use relative submodule URLs (`../hoa-server.git`) so a clone of either GitHub or Gitee resolves the
submodule on the same host. Mirror the fork repositories to both hosts.

If provenance isolation is wanted for every upstream, add `addon/`, `glue/` and `launcher/` as
submodules too; then the monorepo holds only `shared/`, `tools/`, `docs/`, `scripts/` and `config/`.

## Steps

1. Choose the top-level license (GPL-3.0 recommended; MIT only for original standalone code).
2. Create fork repositories for the parts that become submodules (`hoa-server`, `hoa-client`, and
   optionally `hoa-addon`, `hoa-glue`, `hoa-launcher`) on GitHub and Gitee; preserve history with
   `git filter-repo --subdirectory-filter` or `git subtree split`.
3. `git submodule add ../hoa-server server` and `git submodule add ../hoa-client client`; commit
   `.gitmodules`.
4. CI checkout gains `submodules: recursive`; the Gitee mirror includes the submodule repositories.
5. Release tooling: `git archive` of the superproject does **not** contain submodule files. Update
   `Get-CommittedTree` and package resolution in `tools/release.ps1` to archive each submodule or to
   read the checked-out submodule tree; addon/glue/launcher packages would need the same treatment
   if they become submodules.
6. For a GPL-3.0 server, replace the GPL-2.0-only MySQL client and the OpenSSL 1.0.2 bundle with
   compatible dependencies; otherwise keep the server GPL-2.0 as a separate program.
7. Normalize the license files: `LICENSES/` with GPL-2.0, GPL-3.0, MIT, Apache-2.0 and OFL-1.1,
   an accurate `LICENSE-NOTICE.md`, and a regenerated `THIRD-PARTY-NOTICES.md`.

Until the split is done, the per-directory licenses and `LICENSE-NOTICE.md` remain the source of
truth; do not relicense a GPL-2.0-only part as GPL-3.0 or MIT.
