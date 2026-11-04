# CI

`.github/workflows/ci.yml` runs on every pull request and push to `main`:

| Job | What it does |
| --- | --- |
| `docs-check` | Checks English/Chinese README pairs, relative links and `provenance.yaml`/`UPSTREAM.md` records |
| `addon-lua` | Parses every addon and GlueXML Lua file with LuaJIT |
| `launcher-build` | `dotnet build` for the Avalonia launcher |
| `client-check` | `cargo check -p hoa` for the client workspace |
| `server-build` | CMake configure + `mangosd` build on Ubuntu 24.04 |

Branch protection on `main` requires these five checks; a change that fails any of them cannot be merged. Locally, run the same checks with `scripts/build.ps1`/`build.sh` (addon, launcher, client, server) and `python scripts/check-docs.py`.
