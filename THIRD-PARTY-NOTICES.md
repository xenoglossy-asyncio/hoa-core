# Third-party notices

Hordes of Azeroth is licensed under the GNU General Public License v3.0 (see `LICENSE`). It builds on, ships with or downloads the following projects, each under its own licence. The server's source is GPL-2.0-or-later and is distributed under GPL-3.0; its bundled dependencies are compatible with that licence.

Hordes of Azeroth is not affiliated with or endorsed by Blizzard Entertainment. It contains no Blizzard files: the game client is our own build of benilla, which reads the player's own World of Warcraft 1.12.1 data, and the launcher builds everything else it needs from that data on the player's PC.

| Project | Used for | Licence | Source |
| --- | --- | --- | --- |
| benilla | The game client (our fork: `client`, built as `HordesOfAzeroth.exe`) | MIT OR Apache-2.0 | https://github.com/samwhosung/benilla |
| Rust crates in the client | Bevy, wgpu, mlua's Lua and the other libraries benilla builds on, compiled into `HordesOfAzeroth.exe`; every crate with its full licence text is listed in `CLIENT-LICENSES.md` next to the game | Each crate's own licence (MIT, Apache-2.0, MPL-2.0, zlib, BSD and similar) | https://crates.io |
| VMaNGOS | The game server (our fork: `server`) | GPL-3.0 distribution; source headers are GPL-2.0-or-later | https://github.com/vmangos/core |
| MariaDB Connector/C 3.4.10 | Server database client bundled for Windows (`libmariadb.dll` and `server/dep/windows/include/mysql`) | LGPL-2.1-or-later (dynamic link) | https://mariadb.org/connector-c/ |
| OpenSSL 3.5.9 LTS | `libcrypto` and the legacy provider bundled for the Windows server (`libcrypto-3-x64.dll`, `legacy.dll`) | Apache-2.0 | https://www.openssl.org/ |
| VMaNGOS world database | The base of the shipped world database (`world-db`), with our changes applied | GPL-3.0 distribution; base data from VMaNGOS | https://github.com/vmangos/core/releases |
| MariaDB Server | The local database, downloaded and run as a separate program | GPL-2.0 (version 2 only) | https://mariadb.org |
| gSOAP, libmpq, G3D, recastnavigation, cpptrace, utf8cpp, zlib, bzip2 and other server dependencies | Server build dependencies under `server/dep` | GPL-2.0-or-later, BSD, zlib, MIT, Boost and similar; all GPL-3.0-compatible | See `server/dep` and `THIRD-PARTY-NOTICES.md` |
| Barlow Bold | Health numbers font in the addon (`Interface/AddOns/HordesOfAzeroth/Fonts`, licence in `Barlow-OFL.txt` beside it) | SIL Open Font License 1.1 | https://github.com/jpt/barlow |
| Noto Sans SC / Noto Sans TC | Chinese font fallbacks in the addon (`Fonts/NotoSansSC-OFL.txt`, `Fonts/NotoSansTC-OFL.txt`) | SIL Open Font License 1.1 | https://fonts.google.com/noto |
| Avalonia, Mono.Nat | Launcher windowing and NAT helpers | MIT | https://avaloniaui.net/ , https://github.com/AlanMcGovern/Mono.Nat |
| Microsoft Visual C++ Redistributable | Runtime DLLs next to the server and map tools | Microsoft Software License Terms (redistributable files) | https://learn.microsoft.com/cpp/windows/latest-supported-vc-redist |

MariaDB Server is downloaded by the launcher from its own release page and runs as a separate process; the server links MariaDB Connector/C, not the MariaDB Server. The client and the VMaNGOS-based server are built from our forks' source: [hordes-of-azeroth-client](https://github.com/jonhaldors/hordes-of-azeroth-client) and [hordes-of-azeroth-server](https://github.com/jonhaldors/hordes-of-azeroth-server).

## benilla

benilla is dual-licensed under the MIT licence and the Apache License 2.0; the full Apache text is `LICENSE-APACHE` in the client source.

```
MIT License

Copyright (c) 2026 Sam

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
