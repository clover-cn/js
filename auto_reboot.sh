#!/bin/bash

# 检查当前用户是否具有 root 权限
if [[ $(id -u) -ne 0 ]]; then
    echo "此脚本必须以root身份运行!"
    exit 1
fi
echo "准备安装ntpdate服务..."
sleep 2  # 等待 2 
yum install ntpdate
ntpdate -u ntp.api.bz
echo "准备安装at服务..."
sleep 2  # 等待 2 
sudo yum install at

# 更改系统时间为北京时间
timedatectl set-timezone Asia/Shanghai
timedatectl set-ntp true
timedatectl set-ntp false
ntpdate pool.ntp.org
echo "已更改系统时间为北京时间"

# 创建自动重启脚本文件
cat > user_reboot.sh << EOF
#!/bin/bash

# 设置重启时间为每天凌晨 3 点
restart_time="03:00"

# 获取当前系统时间和日期
current_time=\$(date +"%H:%M")

# 检查是否已经超过重启时间
if [[ "\$current_time" > "\$restart_time" ]]; then
    echo "当前时间已超过重新启动时间。计划明天重新启动。"
    restart_date=\$(date -d "tomorrow \$restart_time" +"%Y-%m-%d %H:%M:%S")
else
    echo "计划今天重新启动。"
    restart_date=\$(date -d "today \$restart_time" +"%Y-%m-%d %H:%M:%S")
fi

echo "计划重新启动： \$restart_date"

# 启动at服务
sudo systemctl start atd
sleep 1
# 使用 at 命令安排重启任务
echo "/sbin/reboot" | at \$restart_time
EOF

# 赋予脚本执行权
chmod +x user_reboot.sh

# 将定时任务添加到 cronta
echo "正在添加定时任务..."
sleep 2
(crontab -l ; echo "0 3 * * * $(pwd)/user_reboot.sh") | crontab -

echo "自动重新启动设置已完成"

echo "当前用户的定时任:"
crontab -l
