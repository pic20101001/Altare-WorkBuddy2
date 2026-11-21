FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV VNC_PW=workbuddy123
ENV VNC_RESOLUTION=1280x720

RUN apt update && apt install -y \
    xfce4 xfce4-terminal \
    tigervnc-standalone-server \
    novnc websockify \
    supervisor \
    wget curl gpg \
    fonts-noto-cjk \
    && apt autoremove -y \
    && apt clean \
    && rm -rf /var/lib/apt/lists/*

# 创建普通用户
RUN useradd -m workbuddy && echo "workbuddy:workbuddy" | chpasswd && usermod -aG sudo workbuddy

# 下载并安装 WorkBuddy
WORKDIR /tmp
RUN wget -O workbuddy.deb https://download.workbuddy.ai/linux/WorkBuddy_latest_amd64.deb
RUN dpkg -i workbuddy.deb || apt -f install -y
RUN rm -f workbuddy.deb

# VNC 目录 + 权限归属
RUN mkdir -p /home/workbuddy/.vnc
RUN chown -R workbuddy:workbuddy /home/workbuddy/.vnc

# 写入supervisor配置（改用单引号写入，规避shell变量提前解析bug）
RUN mkdir -p /etc/supervisor/conf.d
RUN cat > /etc/supervisor/conf.d/workbuddy.conf <<'EOF'
[program:vnc]
command=su - workbuddy -c "vncserver :1 -geometry %(ENV_VNC_RESOLUTION)s -depth 24 -SecurityTypes VncAuth"
autostart=true
autorestart=true
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0

[program:novnc]
command=websockify --web /usr/share/novnc 8080 localhost:5901
autostart=true
autorestart=true
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0
EOF

EXPOSE 8080

CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]
