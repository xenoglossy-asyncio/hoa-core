# License texts

The repository is a monorepo with per-directory licenses. This folder keeps the full texts for the
licenses used across it; the authoritative copyright notices stay next to the code they cover.

| File | Used by |
| --- | --- |
| `GPL-3.0.txt` | top-level original code, `server/`, `addon/`, `glue/`, `launcher/`, `config/`, `localization/`, `shared/`, `scripts/`, `tools/` |
| `GPL-2.0.txt` | VMaNGOS source headers (GPL-2.0-or-later) and third-party gSOAP/libmpq; MariaDB Server is downloaded separately under GPL-2.0-only |
| `LGPL-2.1.txt` | MariaDB Connector/C 3.4.10 shipped with the Windows server (dynamic link) |
| `MIT.txt`, `Apache-2.0.txt` | `client/` (dual-licensed, choose either); OpenSSL 3.5.9 uses Apache-2.0 |
| `OFL-1.1.txt` | addon fonts; each font keeps its own copyright file under `Fonts/` |

The repository's own code and the server distribution are GPL-3.0. Imported files keep their
upstream notices: VMaNGOS headers are GPL-2.0-or-later, the client is MIT OR Apache-2.0, MariaDB
Connector/C is LGPL-2.1-or-later, and OpenSSL 3 is Apache-2.0. All of these are compatible with a
GPL-3.0 distribution. MariaDB Server itself is GPL-2.0-only, but the launcher downloads and runs
it as a separate program; it is not linked into the server.

## SPDX headers

Repository-owned scripts carry a machine-readable SPDX identifier near the top of the file:

- `scripts/` (repository build/check tooling) uses `GPL-3.0-only`.
- `tools/` (release, Linux build and i18n tooling) uses `GPL-3.0-only`.

Imported tools and derived sources keep their upstream headers and notices; generated data has no
header of its own. Per-directory `LICENSE`/`UPSTREAM.md` files remain authoritative for those parts.
