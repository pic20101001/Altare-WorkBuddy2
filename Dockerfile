FROM debian:bookworm-slim
ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=:0
ENV VNC_RESOLUTION=1280x720
ENV VNC_PW=WB@123456
ENV RUN_XTERM=no

# 安装基础组件：tigervnc、noVNC、Fluxbox、Electron依赖、supervisor
RUN apt update && apt install -y --no-install-recommends \
    tigervnc-standalone-server \
    novnc \
    fluxbox \
    wget curl ca-certificates \
    libnss3 libasound2 libgbm1 libgtk-3-0 libnotify4 libxss1 \
    supervisor && \
    apt clean && rm -rf /var/lib/apt/lists/*

# 下载并安装 WorkBuddy 国际版 Linux deb
RUN wget -O /tmp/WorkBuddy_amd64.deb https://download.workbuddy.ai/linux/WorkBuddy_amd64.deb && \
    dpkg -i /tmp/WorkBuddy_amd64.deb || true && \
    apt -f install -y && \
    rm /tmp/WorkBuddy_amd64.deb

# Supervisor配置：VNC、noVNC、WorkBuddy保活
RUN mkdir -p /etc/supervisor/conf.d
COPY <<EOF /etc/supervisor/conf.d/workbuddy-stack.conf
[program:vnc]
command=bash -c "vncserver :0 -geometry %(ENV_VNC_RESOLUTION)s -depth 16 -SecurityTypes VncAuth"
autostart=true
autorestart=true
stdout_logfile=/var/log/vnc.log
stderr_logfile=/var/log/vnc.err

[program:novnc]
command=websockify --web /usr/share/novnc 8080 localhost:5900
autostart=true
autorestart=true
stdout_logfile=/var/log/novnc.log
stderr_logfile=/var/log/novnc.err

[program:workbuddy]
command=bash -c "workbuddy --no-sandbox --disable-gpu --disable-gpu-sandbox"
autostart=true
autorestart=true
stdout_logfile=/var/log/workbuddy.log
stderr_logfile=/var/log/workbuddy.err
EOF

# 初始化VNC密码目录
RUN mkdir -p /root/.vnc && \
    echo "%ENV_VNC_PW%" | vncpasswd -f > /root/.vnc/passwd && chmod 600 /root/.vnc/passwd

EXPOSE 8080
CMD ["/usr/bin/supervisord", "-n"]
