# MATRIX TOOL CONSOLE

> A Matrix-styled, browser-based console for authorized security testing:
> TCP port scan, SQL injection detection/extraction and XSS scanning against
> your own lab (DVWA by default). UI is in Chinese.

黑客帝国风格的单页 Web 控制台，把三个安全测试工具收进同一个浏览器界面：

| 模块 | 功能 | 后端 |
| --- | --- | --- |
| **PORT SCANNER** | TCP 端口探测、服务识别、banner / TLS 指纹 | `matrix-login/python/scanner.py` |
| **SQL INJECTION** | 报错 / UNION / 布尔 / 时间注入检测，自动枚举库、表、字段并导出数据 | `sqlscan` |
| **XSS SCANNER** | 反射型 / 存储型 / DOM 型，含绕过载荷与浏览器执行验证 | `xsscan` |

> ⚠️ **仅限授权目标。** 三个模块都会向目标发起真实请求。请只在你拥有或已获得明确书面授权的系统上使用；默认目标为本地 DVWA 靶场。
>
> 本项目不附带任何靶场，也不包含批量攻击或持久化能力，仅用于安全学习、靶场练习和授权测试。

## 快速开始

### 环境要求

- **PHP 7.3+**（需启用 `proc_open`，PHP 内置服务器即可）
- **Python 3.9+**
- 可选：Chrome 或 Edge（XSS 的浏览器执行验证使用 Selenium；未安装时自动降级为静态分析）

### Windows 一键启动

1. 安装 PHP 与 Python，并加入 `PATH`（phpStudy 的 PHP 也能自动识别）
2. 双击项目根目录的 `start_matrix.bat`
3. 启动器会自动创建 `venv`、安装依赖、选择空闲端口并打开浏览器

默认访问地址：<http://127.0.0.1:18081/matrix-login/>

可在命令行指定端口与绑定地址：

```bat
start_matrix.bat 19000
start_matrix.bat 18081 localhost
start_matrix.bat 18081 192.168.1.10   :: 局域网可访问，注意风险
```

### 手动启动（Windows / macOS / Linux）

```bash
# 1. 安装 Python 依赖
python3 -m venv venv
venv/bin/python -m pip install -r requirements.txt
# Windows 写法：
#   py -m venv venv
#   venv\Scripts\python.exe -m pip install -r requirements.txt

# 2. 启动 PHP 内置服务器
php -S 127.0.0.1:18081 -t . matrix-router.php
```

然后打开 <http://127.0.0.1:18081/matrix-login/>。根路径 `/` 会自动跳转。

`matrix-router.php` 只暴露 `matrix-login/` 目录；如果改用 Apache / Nginx，请把
`matrix-login/` 部署到站点目录，并确认 `config.php` 中的 `MATRIX_PROJECT_ROOT`
指向本仓库根目录（默认按相对路径自动计算，无需修改）。

### 默认账号

| 用户名 | 密码 |
| --- | --- |
| `admin` | `Matrix@2026` |

修改 `matrix-login/login.php` 顶部的 `AUTH_USERNAME` / `AUTH_PASSWORD`，
或启动前设置环境变量 `MATRIX_USERNAME` / `MATRIX_PASSWORD`。
**部署到局域网或公网前请务必修改。**

## 使用说明

### PORT SCANNER

填写域名 / IPv4 / IPv6（可带 `http://` 前缀，会自动清洗），勾选默认端口或输入
自定义端口（`8080,3306,9000-9010`），调整超时与 banner 抓取后点击 `INITIATE SCAN`。
单次最多 128 个端口，结果可导出 JSON。

### SQL INJECTION

填写目标 URL、Cookie、参数名与检测技术。默认目标为：

```
http://127.0.0.1/vulnerabilities/sqli/?id=1
```

检测确认后会自动枚举数据库、表、字段并导出数据；勾选“只检测”可跳过数据提取。
Cookie 请从已登录靶场的浏览器中复制，例如 `PHPSESSID=...; security=low`。

### XSS SCANNER

选择全部 / 反射型 / 存储型 / DOM 型。目标 URL 留空时使用 DVWA 默认地址；
单一模式时可覆盖。勾选“浏览器执行验证”后，工具用 Selenium 打开真实浏览器，
确认 `alert` 是否执行；未安装 Selenium 时 DOM 模式降级为静态分析。

存储型 XSS 会向靶场数据库写入测试记录，请仅对本地或授权靶场使用。

## 目录结构

```
matrix-tool-console/
├── start_matrix.bat            # Windows 一键启动器
├── matrix-router.php           # PHP 内置服务器路由（只暴露 matrix-login/）
├── requirements.txt            # requests + selenium
├── main.py / xss_main.py       # SQLi / XSS 命令行入口（供 Web 后端调用）
├── sqlscan/                    # SQL 注入检测与枚举
├── xsscan/                     # XSS 检测与浏览器验证
└── matrix-login/
    ├── login.php               # 登录页（凭证在此修改）
    ├── index.php               # 三工具操作台
    ├── logout.php
    ├── scan.php                # 端口扫描 API（NDJSON 流式返回）
    ├── tool_api.php            # SQLi / XSS 执行 API（NDJSON 流式返回）
    ├── config.php              # 项目根目录与独立 Session 名称
    ├── assets/css              # 界面样式
    ├── assets/js               # 代码雨、交互与事件流
    └── python/
        ├── scanner.py          # 端口扫描器（仅标准库）
        ├── run_tool.py         # PHP → sqlscan/xsscan 的 stdin 桥接
        └── netscan/            # 端口解析、DNS、TCP/TLS/HTTP 探测
```

## 配置

| 配置项 | 位置 | 说明 |
| --- | --- | --- |
| 登录凭证 | `matrix-login/login.php` 顶部常量 | 或使用环境变量覆盖 |
| 项目根目录 | `matrix-login/config.php` → `MATRIX_PROJECT_ROOT` | 默认取上级目录 |
| 默认目标 / Cookie | `sqlscan/config.py`、`xsscan/config.py` | 页面表单可逐次覆盖 |
| 项目 Python 运行时 | 根目录 `venv` | `start_matrix.bat` 自动创建 |
| 端口扫描运行时 | `matrix-login/venv` | 缺失时由 `scan.php` 自动创建并回退系统 Python |

## 安全设计

- matrix 使用独立 Session 名称 `MATRIXLOGIN`，不会与 DVWA 的 `PHPSESSID` 互相顶掉
- 登录失败 5 次锁定 30 秒，成功后重建 Session
- 所有 API 都要求登录会话 + CSRF Token（`hash_equals`）
- 每次执行有冷却时间，执行总超时 240 秒，客户端断开时终止子进程
- 工具参数经白名单校验后通过 stdin JSON 传递，不拼接进命令行
- 前端必须勾选授权确认，后端同样校验 `authorized`
- 检测工具单线程、可限速；端口扫描最多 32 并发，只做 TCP connect 探测
- 默认只对本地 DVWA 地址发请求，目标需在页面中手动填写

## 说明与限制

- SQL 注入载荷与提取逻辑以 **MySQL / MariaDB** 为主（DVWA 默认），其他数据库主要支持检测
- `GROUP_CONCAT` 受 `group_concat_max_len` 限制，数据过多会被截断
- 布尔盲注逐字符提取，速度较慢属正常
- XSS 的浏览器执行验证依赖本机 Chrome / Edge 与 Selenium；首次运行可能需要联网下载驱动
- 默认密码写在源码中仅为演示，正式环境请改用环境变量或接入真实鉴权

## License

[MIT](LICENSE)
