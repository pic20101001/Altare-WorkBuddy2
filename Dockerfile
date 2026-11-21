FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV VNC_PW=workbuddy123
ENV VNC_RESOLUTION=1280x720

# 更新源、安装依赖
RUN apt update && apt install -y \
    xfce4 xfce4-terminal \
    tigervnc-standalone-server \
    novnc websockify \
    supervisor \
    wget curl gpg \
    fonts-noto-cjk \
    && apt clean && rm -rf /var/lib/apt/lists/*

# 创建运行用户
RUN useradd -m workbuddy && echo "workbuddy:workbuddy" | chpasswd && adduser workbuddy sudo
USER workbuddy
WORKDIR /home/workbuddy

# 下载安装 WorkBuddy
RUN wget -O workbuddy.deb https://download.workbuddy.ai/linux/WorkBuddy_latest_amd64.deb
USER root
RUN dpkg -i workbuddy.deb || apt -f install -y
RUN rm -f workbuddy.deb

# 配置vnc
USER workbuddy
RUN mkdir -p /home/workbuddy/.vnc
RUN echo "$VNC_PW" | vncpasswd -f > /home/workbuddy/.vnc/passwd
RUN chmod 600 /home/workbuddy/.vnc/passwd

# supervisor配置
USER root
RUN mkdir -p /etc/supervisor/conf.d
COPY <<EOF /etc/supervisor/conf.d/workbuddy.conf
[program:vnc]
command=su - workbuddy -c "vncserver :1 -geometry %(ENV_VNC_RESOLUTION)s -depth 24"
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
