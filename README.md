# HAX BOT 7.8

HAX Telegram Bot 一键安装版。支持 Ubuntu / Debian VPS，适配 AMD64 / ARM64。安装后使用 systemd 守护两个进程：

- `hax-bot.service`：Telegram 机器人、机器续期提醒、数据中心变化通知。
- `hax-bot-collector.service`：定时采集 HAX 数据中心状态，写入 `data/data_center.json`、`data/data_center.txt` 和兼容旧版的 `test.txt`。

## 目录结构

```text
hax-bot-7.8/
├── app/
│   ├── bot/main.py
│   ├── collector/hax.py
│   ├── collector/runner.py
│   ├── config.py
│   └── storage.py
├── data/.gitkeep
├── logs/.gitkeep
├── install.sh
├── start.sh
├── stop.sh
├── restart.sh
├── status.sh
├── update.sh
├── uninstall.sh
├── upload_to_github.sh
├── requirements.txt
└── README.md
```

## 一键安装

上传到 GitHub 后执行：

```bash
curl -fsSL https://raw.githubusercontent.com/mingyueqianli/hax-bot-7.7/main/install.sh | bash
```

非交互安装：

```bash
curl -fsSL https://raw.githubusercontent.com/mingyueqianli/hax-bot-7.7/main/install.sh | HAX_TOKEN="你的TelegramBotToken" HAX_INTERVAL=30 bash
```

如果你的仓库不是 `mingyueqianli/hax-bot-7.7`，先改 `install.sh` 顶部的 `REPO_URL`。

## 手动安装

```bash
apt update -y
apt install -y python3 python3-pip python3-venv git curl
cd /opt
git clone https://github.com/mingyueqianli/hax-bot-7.7.git hax-bot
cd /opt/hax-bot
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
echo "你的TelegramBotToken" > token.txt
echo "30" > interval.txt
chmod 600 token.txt interval.txt
bash install.sh
```

## 服务管理

```bash
systemctl status hax-bot.service hax-bot-collector.service
systemctl restart hax-bot.service hax-bot-collector.service
journalctl -u hax-bot -f
journalctl -u hax-bot-collector -f
```

也可以使用仓库内脚本：

```bash
./status.sh
./restart.sh
./stop.sh
./start.sh
./update.sh
```

## Telegram 命令

- `/start`：查看帮助。
- `/new`：添加机器续期提醒。
- `/info`：查看机器列表和剩余时间。
- `/rename`：修改备注或续期日期。
- `/delmachine`：删除机器，支持 `1,3` 或 `1-3`。
- `/monitor`：开启/关闭 HAX 数据中心变化提醒。
- `/status`：查看当前采集到的数据中心状态。
- `/cancel`：取消当前操作。

## 重要文件

- `token.txt`：Telegram Bot Token，权限自动设置为 `600`，不会提交到 GitHub。
- `interval.txt`：采集间隔，单位秒，默认 `30`。
- `data/user_data.json`：用户机器提醒和监控状态。
- `data/data_center.json`：结构化数据中心状态。
- `data/data_center.txt`：文本版数据中心状态。
- `test.txt`：兼容旧版脚本。

## 更新

```bash
cd /opt/hax-bot
./update.sh
```

更新脚本会保留 `token.txt`、`interval.txt`、`data/` 和 `logs/`。

## 卸载

```bash
cd /opt/hax-bot
./uninstall.sh
```

默认会询问是否删除 `/opt/hax-bot` 目录。
