#!/bin/bash
set -Eeuo pipefail

APP_NAME="hax-bot"
BASE_DIR="/opt"
SERVICE_NAME="hax-bot"
REPO_URL="${REPO_URL:-https://github.com/mingyueqianli/hax-bot-7.7.git}"
BRANCH="${BRANCH:-main}"
APP_DIR="$BASE_DIR/$APP_NAME"
BACKUP_DIR="$BASE_DIR/${APP_NAME}-backup-$(date +%Y%m%d-%H%M%S)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "${BLUE}[STEP]${NC} $1"; }

require_root() {
    if [ "${EUID}" -ne 0 ]; then
        log_error "请使用 root 用户运行：sudo bash install.sh"
        exit 1
    fi
}

safe_read() {
    local prompt="$1"
    local var_name="$2"
    local input=""
    if [ -r /dev/tty ]; then
        read -r -p "$prompt" input < /dev/tty
    else
        read -r -p "$prompt" input
    fi
    printf -v "$var_name" '%s' "$input"
}

install_packages() {
    log_step "安装基础环境..."
    if ! command -v apt >/dev/null 2>&1; then
        log_error "当前脚本仅支持 Debian/Ubuntu apt 系统"
        exit 1
    fi
    apt update -y
    DEBIAN_FRONTEND=noninteractive apt install -y python3 python3-pip python3-venv git curl ca-certificates
}

backup_old_install() {
    if [ ! -d "$APP_DIR" ]; then
        return
    fi
    log_warn "发现旧版本：$APP_DIR"
    mkdir -p "$BACKUP_DIR"
    for item in token.txt interval.txt config.env data logs test.txt; do
        if [ -e "$APP_DIR/$item" ]; then
            cp -a "$APP_DIR/$item" "$BACKUP_DIR/" || true
        fi
    done
    log_info "旧数据已备份到：$BACKUP_DIR"
    systemctl stop ${SERVICE_NAME}.service ${SERVICE_NAME}-collector.service 2>/dev/null || true
    rm -rf "$APP_DIR"
}

clone_repo() {
    log_step "Clone 仓库..."
    mkdir -p "$BASE_DIR"
    git config --global http.postBuffer 524288000 || true
    if ! git clone --depth=1 --branch "$BRANCH" "$REPO_URL" "$APP_DIR" 2>/tmp/hax-bot-clone.err; then
        log_warn "clone 失败，尝试修复 DNS 后重试..."
        cat /tmp/hax-bot-clone.err || true
        echo "nameserver 8.8.8.8" > /etc/resolv.conf || true
        git clone --depth=1 --branch "$BRANCH" "$REPO_URL" "$APP_DIR"
    fi
    cd "$APP_DIR"
    log_info "当前目录：$(pwd)"
}

restore_backup() {
    if [ ! -d "$BACKUP_DIR" ]; then
        return
    fi
    log_step "恢复旧数据..."
    for item in token.txt interval.txt config.env data logs test.txt; do
        if [ -e "$BACKUP_DIR/$item" ]; then
            rm -rf "$APP_DIR/$item"
            cp -a "$BACKUP_DIR/$item" "$APP_DIR/" || true
        fi
    done
}

setup_python() {
    log_step "配置 Python 虚拟环境..."
    cd "$APP_DIR"
    if [ ! -f requirements.txt ]; then
        log_error "requirements.txt 不存在，请检查仓库文件"
        exit 1
    fi
    python3 -m venv venv
    # shellcheck source=/dev/null
    source venv/bin/activate
    pip install --upgrade pip setuptools wheel
    pip install -r requirements.txt
    mkdir -p data logs
}

write_config() {
    log_step "写入 TOKEN 和采集间隔..."
    local token="${HAX_TOKEN:-}"
    local interval="${HAX_INTERVAL:-}"
    local mode="${HAX_MODE:-}"

    # 如果是升级安装，优先复用旧版配置，避免重复输入。
    if [ -z "$token" ] && [ -f "$APP_DIR/token.txt" ]; then
        token="$(cat "$APP_DIR/token.txt" | tr -d '\r\n')"
    fi
    if [ -z "$interval" ] && [ -f "$APP_DIR/interval.txt" ]; then
        interval="$(cat "$APP_DIR/interval.txt" | tr -d '\r\n')"
    fi

    if [ -z "$mode" ] && [ -r /dev/tty ]; then
        echo "===================="
        echo "请选择模式:"
        echo "1) 一键模式（默认间隔 30 秒）"
        echo "2) 交互模式（输入 TOKEN 和间隔）"
        echo "===================="
        safe_read "输入 [1/2]: " mode
    fi
    mode="${mode:-1}"

    while [ -z "$token" ]; do
        safe_read "🔑 TOKEN（必填）: " token
        if [ -z "$token" ]; then
            log_error "TOKEN 不能为空"
        fi
    done

    if [ -z "$interval" ]; then
        if [ "$mode" = "2" ]; then
            while true; do
                safe_read "⏱ INTERVAL（秒）: " interval
                if [[ "$interval" =~ ^[0-9]+$ ]] && [ "$interval" -gt 0 ]; then
                    break
                fi
                log_error "请输入有效正整数"
            done
        else
            interval="30"
            log_info "使用默认间隔：${interval}s"
        fi
    fi

    if ! [[ "$interval" =~ ^[0-9]+$ ]] || [ "$interval" -le 0 ]; then
        log_error "INTERVAL 必须是正整数"
        exit 1
    fi

    printf '%s\n' "$token" > "$APP_DIR/token.txt"
    printf '%s\n' "$interval" > "$APP_DIR/interval.txt"
    cat > "$APP_DIR/config.env" <<EOF
HAX_APP_DIR=$APP_DIR
HAX_INTERVAL=$interval
EOF
    chmod 600 "$APP_DIR/token.txt" "$APP_DIR/interval.txt" "$APP_DIR/config.env"
}

create_services() {
    log_step "创建 systemd 服务..."
    systemctl stop ${SERVICE_NAME}.service ${SERVICE_NAME}-collector.service 2>/dev/null || true

    cat > /etc/systemd/system/${SERVICE_NAME}.service <<EOF
[Unit]
Description=HAX BOT 7.8 Telegram Service
After=network.target network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=$APP_DIR
EnvironmentFile=-$APP_DIR/config.env
Environment="PYTHONPATH=$APP_DIR"
Environment="PATH=$APP_DIR/venv/bin:/usr/local/bin:/usr/bin:/bin"
ExecStart=$APP_DIR/venv/bin/python -m app.bot.main
ExecStop=/bin/kill -TERM \$MAINPID
Restart=always
RestartSec=10
StandardOutput=append:$APP_DIR/logs/bot.log
StandardError=append:$APP_DIR/logs/bot_error.log

[Install]
WantedBy=multi-user.target
EOF

    cat > /etc/systemd/system/${SERVICE_NAME}-collector.service <<EOF
[Unit]
Description=HAX BOT 7.8 Collector Service
After=network.target network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=$APP_DIR
EnvironmentFile=-$APP_DIR/config.env
Environment="PYTHONPATH=$APP_DIR"
Environment="PATH=$APP_DIR/venv/bin:/usr/local/bin:/usr/bin:/bin"
ExecStart=$APP_DIR/venv/bin/python -m app.collector.runner
ExecStop=/bin/kill -TERM \$MAINPID
Restart=always
RestartSec=10
StandardOutput=append:$APP_DIR/logs/collector.log
StandardError=append:$APP_DIR/logs/collector_error.log

[Install]
WantedBy=multi-user.target
EOF
}

start_services() {
    log_step "启动服务..."
    pkill -f "python.*app.bot.main" 2>/dev/null || true
    pkill -f "python.*app.collector.runner" 2>/dev/null || true
    systemctl daemon-reload
    systemctl enable ${SERVICE_NAME}.service ${SERVICE_NAME}-collector.service
    systemctl restart ${SERVICE_NAME}.service ${SERVICE_NAME}-collector.service
    sleep 3
}

check_status() {
    local svc="$1"
    if systemctl is-active --quiet "$svc"; then
        log_info "✅ $svc 运行中"
        return 0
    fi
    log_error "❌ $svc 启动失败"
    systemctl status "$svc" --no-pager || true
    return 1
}

print_done() {
    local token interval
    token="$(cat "$APP_DIR/token.txt")"
    interval="$(cat "$APP_DIR/interval.txt")"
    echo ""
    echo "================================"
    echo "✅ HAX BOT 7.8 安装完成"
    echo "================================"
    echo "📦 路径: $APP_DIR"
    if [ "${#token}" -gt 12 ]; then
        echo "🔑 TOKEN: ${token:0:8}...${token: -4}"
    else
        echo "🔑 TOKEN: 已写入 token.txt"
    fi
    echo "⏱ INTERVAL: ${interval}s"
    echo ""
    echo "📋 systemd 服务管理:"
    echo "  状态: systemctl status ${SERVICE_NAME} ${SERVICE_NAME}-collector"
    echo "  重启: systemctl restart ${SERVICE_NAME} ${SERVICE_NAME}-collector"
    echo "  日志: journalctl -u ${SERVICE_NAME} -f"
    echo "       journalctl -u ${SERVICE_NAME}-collector -f"
    echo ""
    echo "📁 应用日志:"
    echo "  tail -f $APP_DIR/logs/bot.log"
    echo "  tail -f $APP_DIR/logs/collector.log"
    echo "================================"
}

main() {
    echo "🚀 HAX BOT 7.8 安装脚本（GitHub 完整版）"
    require_root
    install_packages
    backup_old_install
    clone_repo
    restore_backup
    setup_python
    write_config
    create_services
    start_services
    check_status ${SERVICE_NAME}.service
    check_status ${SERVICE_NAME}-collector.service
    print_done
}

main "$@"
