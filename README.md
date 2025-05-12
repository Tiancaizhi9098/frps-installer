# FRP服务端一键安装脚本

这是一个适用于Linux系统的frps (FRP服务端) 一键安装脚本。该脚本能够帮助您快速部署FRP服务端，并自动配置systemd服务实现开机自启动。

## 功能特点

- ✅ 支持多个版本选择（包括最新版本）
- ✅ 支持INI和TOML两种配置文件格式
- ✅ 自动检测系统架构（支持x86_64、arm64、arm）
- ✅ 交互式配置所有重要参数
- ✅ 随机生成安全Token
- ✅ 支持HTTP和HTTPS协议
- ✅ 自动配置systemd服务实现开机自启动
- ✅ 详细的安装日志和配置备份
- ✅ 非root用户也可以安装（部分功能可能受限）

## 版本说明

- **v0.51.3**：使用ini格式配置文件，推荐使用此版本（稳定）
- **最新版本**：自动获取GitHub最新版本
- **自定义版本**：可指定任意版本号

## 系统要求

- Linux系统（推荐使用支持systemd的发行版）
- 基本工具: curl, tar

## 快速开始

### 方法1: 直接从GitHub运行

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Tiancaizhi9098/frps-installer/main/install.sh)"
```

### 方法2: 下载后运行

```bash
# 下载脚本
curl -O https://raw.githubusercontent.com/Tiancaizhi9098/frps-installer/main/install_frps.sh

# 添加执行权限
chmod 755 install_frps.sh

# 执行脚本
bash install_frps.sh
```

## 配置选项

脚本运行时会提示您输入以下参数，直接按Enter键将使用默认值：

| 参数 | 默认值 | 说明 |
|------|--------|------|
| frp版本 | v0.51.3 | 可选择v0.51.3(ini格式)或最新版本或自定义版本 |
| 服务器绑定端口 | 7000 | frps服务监听的TCP端口 |
| Dashboard管理面板端口 | 7500 | Web管理界面端口 |
| Dashboard用户名 | admin | 管理员用户名 |
| Dashboard密码 | admin | 管理员密码 |
| 认证Token | 随机生成 | 客户端连接服务端的凭证 |
| 虚拟主机HTTP端口 | 80 | HTTP协议访问端口 |
| 虚拟主机HTTPS端口 | 443 | HTTPS协议访问端口 |
| 服务器域名/IP | 自动检测的服务器IP | 用于子域名功能 |
| 安装目录 | /usr/local/frp | frps程序和配置文件存放位置 |

## 安装位置

- 主程序：`/usr/local/frp/frps`
- 配置文件（INI格式）：`/usr/local/frp/frps.ini`
- 配置文件（TOML格式）：`/usr/local/frp/frps.toml`
- 配置备份：`/usr/local/frp/frps_config_backup.txt`
- 日志文件：`/var/log/frps.log`
- 服务配置：`/etc/systemd/system/frps.service`

## 常用命令

```bash
# 查看服务状态
systemctl status frps

# 启动服务
systemctl start frps

# 停止服务
systemctl stop frps

# 重启服务
systemctl restart frps

# 查看日志
tail -f /var/log/frps.log

# 编辑配置文件(INI格式)
nano /usr/local/frp/frps.ini

# 编辑配置文件(TOML格式)
nano /usr/local/frp/frps.toml
```

## 注意事项

- 推荐使用root权限运行，非root用户可能无法完成某些操作（如自启动配置）
- 安装完成后，请务必保存显示的Token和其他配置信息
- 出于安全考虑，建议修改默认的管理员密码和Dashboard端口
- 脚本不会自动配置防火墙，请根据需要手动开放相关端口
- 修改配置文件后需要重启服务生效：`systemctl restart frps`
- **v0.51.3** 使用的是ini格式配置文件
- **v0.52.0及以上** 版本使用的是toml格式配置文件

## INI和TOML格式区别

- **INI格式** (v0.51.3及之前版本):
  ```ini
  [common]
  bind_port = 7000
  dashboard_port = 7500
  ```

- **TOML格式** (v0.52.0及之后版本):
  ```toml
  bindPort = 7000
  
  webServer.addr = "0.0.0.0"
  webServer.port = 7500
  ```

## 关于FRP

FRP (Fast Reverse Proxy) 是一个可用于内网穿透的高性能的反向代理应用，支持TCP、UDP、HTTP、HTTPS等多种协议。本脚本安装的是FRP的服务端组件(frps)。

更多关于FRP的信息，请访问官方项目：[fatedier/frp](https://github.com/fatedier/frp)

## 问题反馈

如果您在使用过程中遇到任何问题，请在GitHub Issues中提出。

## 许可证

MIT

## 免责声明

本脚本仅用于学习和研究目的，请遵守当地法律法规。作者不对使用本脚本导致的任何问题负责。
