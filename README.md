# Srun_Openwrt
Openwrt可用的深澜校园网客户端，可作为服务自启动，支持自动掉线重连。

# 写在前面

本项目离不开 [Raincorn](https://github.com/rainvalley)、[chillsoul](https://github.com/chillsoul) 的 [rainvalley/Srun_Linux](https://github.com/rainvalley/Srun_Linux) 项目。本项目的核心登录功能仍然使用以上脚本，如果希望采用传统命令后方式登录，或者在其他 Linux 发行版运行，请使用上面的版本。

掉线检测的功能和实现受 [Revincx](https://github.com/Revincx/) 启发。感谢他长期运行的经验，该掉线检测方法在 crontab 每分钟执行一次的情况下，在相当长的时间跨度下（数月）未出现问题。

本人第一次尝试使用编写 Openwrt  Procd init.d 脚本，因此难免有功能性或稳定性问题，请在长期测试稳定性后再作为无人看守脚本运行。~~失联别赖我~~

# 安装方式

0. 首先，停止原来的登录脚本。如果使用 crontab 定时任务，请使用：

   ```bash
   crontab -e
   ```

   ```
   # * * * * * /root/srun.sh username passwd
   ```

   这里建议把先前的任务注释掉。

1. 下载安装脚本。如果无法连接 GitHub，请使用其他方式下载后，再用 SFTP 或 Web 文件管理上传脚本。

```bash
wget https://raw.githubusercontent.com/CHxCOOH/Srun_Openwrt/main/install.sh
```

2. 运行脚本，按提示输入账号密码。

```bash
ash ./install.sh
```

```
输入账号（学号）：2019xxxxxxxx
输入密码：passwd
正在生成 UCI 配置文件 (/etc/config/srun)...
正在复制登录脚本 (/usr/bin/srun.sh)...
正在生成服务配置 (/etc/init.d/srun)...
安装完毕！尝试启动服务...
启动完毕，如果有running字样，说明服务已运行！
running
{
        "srun": {
                "instances": {
                        "srun": {
                                "running": true,
                                "pid": 23961,
                                "command": [
                                        "/bin/ash",
                                        "/usr/bin/srun.sh"
                                ],
                                "term_timeout": 5,
                                "respawn": {
                                        "threshold": 3600,
                                        "timeout": 5,
                                        "retry": 5
                                }
                        }
                }
        }
}
```

3. 如果看到 running，则说明安装成功，可以尝试打开网页，或登录校园网后台自助服务查看登录状态。同时，每次检测到掉线，会自动将掉线时间等信息写入 `/root/login.log` 。

# 卸载方式

简单封装了一键卸载脚本。log 留下没有删除，如有需要请自行删除。

```bash
wget https://raw.githubusercontent.com/CHxCOOH/Srun_Openwrt/main/uninstall.sh
bash ./uninstall.sh
```

# 实现原理 & 补充

* 脚本使用 Openwrt 自带的服务管理、进程守护，保持 srun.sh 一直运行，使得 srun.sh 可以每 5s 检查一次在线状态，如果掉线则重新登录。

```bash
# 常用服务管理指令
service srun disable # 关闭服务自启动
service srun stop # 停止服务
service srun status # 服务状态：running、inactive
service srun info # 服务信息

service srun start # 启动服务
service srun enable # 开启服务自启动

# 也可以通过 ps 命令查看
ps | grep srun
```

* 检测方式：使用 wget 模拟 Edge on Windows 的 UA，每 5 秒访问 http://connect.rom.miui.com/generate_204，如果校园网在线，则应该返回 HTTP 204 状态码（即返回结果为空），否则被重定向至登录页面。根据返回结果判断即可。
* 该方式除常驻一个 bash 脚本以外，性能开销是可以忽略的。但是不建议修改为更高的检测频率。
* 如果查看 log 发现频繁掉线，可能是因为触发了校园网的多设备检测/共享限制。
* 该脚本可以作为防被踢下线的一种解决方案，但是请不要在重要场景（比如考试、重要游戏、抢购等）过度依赖，并作为唯一应对措施。
* 已在 x86 VM Openwrt 测试通过，理论上适用于几乎所有 Openwrt 系统（只要该系统使用 UCI 管理配置文件，并使用 Procd 守护、管理系统服务）。
* 硬路由基于 Openwrt 的官方系统未经过测试，不保证正常使用，如有需要请自行测试或刷成 Openwrt。
* 由于 Openwrt 的备份功能仅备份 `/etc/` 目录，所以在系统重置、升级后会丢失登录脚本。请重新执行安装脚本，安装时会正确覆盖先前的配置文件。
* 如不想在掉线重连时写入 log，请注释掉 `/usr/bin/srun.sh` 第 74-82 行中写 log 的三行。
* 如果因调试用途，需要查看脚本执行详细日志，请去掉安装脚本 139, 140 行（安装前修改，或者卸载后重新执行安装脚本）或 `/etc/init.d/srun` 22, 23 行前面的注释，并重启服务。此时脚本每 5 秒会在 Openwrt 系统日志里输出一行状态信息。

