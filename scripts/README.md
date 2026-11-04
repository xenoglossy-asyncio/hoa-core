# scripts / 开发脚本

计划提供：

- `dev.ps1` / `dev.sh`：启动本地 MariaDB、realmd、world server 和客户端（隔离配置目录）。
- `build.ps1` / `build.sh`：构建服务端（CMake）、客户端（Cargo）、启动器（dotnet）。
- `content.ps1` / `content.sh`：重新生成内容、文本、协议，并跑校验。
- `test.ps1` / `test.sh`：单元测试 + 无头集成测试（登录、语言切换、光环显示）。
- `release.ps1` / `release.sh`：打包服务端、客户端、插件、启动器。

脚本只做编排，不藏业务逻辑；CI 调用同一组脚本。
