# License texts

The repository is a monorepo with per-directory licenses. This folder keeps the full texts for the
licenses used across it; the authoritative copyright notices stay next to the code they cover.

| File | Used by |
| --- | --- |
| `GPL-3.0.txt` | top-level original code, `addon/`, `glue/`, `launcher/`, `config/`, `localization/` |
| `GPL-2.0.txt` | `server/` (VMaNGOS) and `shared/` code/data when used by the server |
| `MIT.txt`, `Apache-2.0.txt` | `client/` (dual-licensed, choose either) |
| `OFL-1.1.txt` | addon fonts; each font keeps its own copyright file under `Fonts/` |

`shared/` is licensed GPL-2.0-or-later (the "or later" wording is in the source headers), so the
GPL-2.0 server and the GPL-3.0 addon can both use it. A GPL-2.0-or-later file can be used under
GPL-3.0, but a GPL-3.0 file cannot be taken back into a GPL-2.0-only work.
