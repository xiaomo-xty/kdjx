# 部署docker项目

口袋觉醒的相关文件可能涉及版权问题，我这里只做学习交流用途，故不提供相关文件。这里放上互联网资源

提取码：i0u0

​[百度网盘](https://pan.baidu.com/share/init?surl=rylbQub6CGm-I0ua-Vis8g)​

该资源来自[T1GM]([https://www.t1gm.com/forum.php?mod=viewthread&tid=28&highlight=%E5%8F%A3%E8%A2%8B%E8%A7%89%E9%86%92​](https://www.t1gm.com/forum.php?mod=viewthread&tid=28&highlight=%E5%8F%A3%E8%A2%8B%E8%A7%89%E9%86%92%E2%80%8B))，与我无关

---

拉取项目

```bash
cd ~
git clone https://gitee.com/xiaomo-xty/kdjx.git
```

进入项目目录

```shell
cd kdjx
```

用`ifconfig`查看主机IP，并修改`start.sh`

```shell
HOST_IP=你的IP
SERVER_NAME=服务器名称
export HOST_IP
docker-compose up -d
```

给予启动脚本权限

```shell
chmod +x ./start.sh
```

将下载得到的`kdjx.tar` 也上传到该目录（可以使用rz命令，也可以用1panel面板的稳健操作）

开始构建并运行

```bash
./start.sh
```

接下来只需要等待，start.sh脚本会完成一切，完成后你就可以去1panel面板查看容器的运行情况

若日志最后几行是下面这样，就是正常的

```bash
account_db_server RUNNING pid 40, uptime 0:00:07
anti_cheat_server RUNNING pid 63, uptime 0:00:07
crash_platform_server RUNNING pid 88, uptime 0:00:07
disable_word_check_server RUNNING pid 51, uptime 0:00:07
game_mongodb RUNNING pid 39, uptime 0:00:07
game_server RUNNING pid 70, uptime 0:00:07
gm_server RUNNING pid 89, uptime 0:00:07
login_server RUNNING pid 91, uptime 0:00:07
nsqadmin RUNNING pid 34, uptime 0:00:07
nsqd RUNNING pid 33, uptime 0:00:07
nsqlsokupd RUNNING pid 35, uptime 0:00:07
online_fight_forward_server RUNNING pid 118, uptime 0:00:06
payment_server RUNNING pid 66, uptime 0:00:07
pvp_server RUNNING pid 54, uptime 0:00:07
storage_server RUNNING pid 41, uptime 0:00:07
```