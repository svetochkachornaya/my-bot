#!/bin/bash
# === НАЛАШТУВАННЯ ===
TG_TOKEN="8728201511:AAHUqmvx7jbobNUiGzCnAONInCd2efLteJY"
ANTHROPIC_KEY="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"
GH_USER="svetochkachornaya"
GH_TOKEN="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"
REPO_NAME="my-bot"
# === ДАЛІ НЕ ЗМІНЮЙ ===

set -e

echo "=== 1. Оновлення системи та встановлення залежностей ==="
apt update && apt upgrade -y
apt install -y git python3 python3-pip python3-venv

echo "=== 2. Клонування репозиторію ==="
cd /root
rm -rf "/root/${REPO_NAME}"
git clone "https://${GH_TOKEN}@github.com/${GH_USER}/${REPO_NAME}.git"
cd "/root/${REPO_NAME}"
git config user.name "auto-deploy"
git config user.email "deploy@server"

echo "=== 3. Налаштування Python venv ==="
python3 -m venv venv
venv/bin/pip install -q --upgrade pip
venv/bin/pip install -q -r requirements.txt

echo "=== 4. Створення .env ==="
cat > /root/${REPO_NAME}/.env << EOF
TELEGRAM_BOT_TOKEN=${TG_TOKEN}
ANTHROPIC_API_KEY=${ANTHROPIC_KEY}
GITHUB_TOKEN=${GH_TOKEN}
GH_USER=${GH_USER}
REPO_NAME=${REPO_NAME}
EOF

echo "=== 5. Налаштування systemd сервісів ==="
cp mybot.service /etc/systemd/system/
cp autodeploy.service /etc/systemd/system/
cp autodeploy.timer /etc/systemd/system/
cp cmdrunner.service /etc/systemd/system/

chmod +x /root/${REPO_NAME}/autodeploy.sh
cp autodeploy.sh /root/autodeploy.sh
chmod +x /root/autodeploy.sh

systemctl daemon-reload
systemctl enable --now mybot.service
systemctl enable --now autodeploy.timer
systemctl enable --now cmdrunner.service

echo ""
echo "=== ГОТОВО! ==="
python3 --version
git --version
echo ""
echo "--- Статус бота ---"
systemctl status mybot.service --no-pager | head -8
echo ""
echo "--- Статус git relay ---"
systemctl status cmdrunner.service --no-pager | head -8
echo ""
echo "--- Статус autodeploy timer ---"
systemctl status autodeploy.timer --no-pager | head -5
