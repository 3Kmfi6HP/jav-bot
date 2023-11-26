# 使用alpine作为基础镜像
FROM alpine

# 安装需要的软件包和依赖库
RUN apk add --update --no-cache \
    bash \
    curl \
    wget \
    jq \
    ffmpeg

# 创建并设置工作目录
WORKDIR /app

# 复制所需文件到容器中
COPY telegram.bot script.sh ./

# 赋予执行权限
RUN chmod +x script.sh telegram.bot

# 下载、解压、赋予执行权限并清理gost
RUN wget -nv -O gost_3.0.0-rc8_linux_amd64v3.tar.gz https://github.com/go-gost/gost/releases/download/v3.0.0-rc8/gost_3.0.0-rc8_linux_amd64v3.tar.gz && \
    tar -xzvf gost_3.0.0-rc8_linux_amd64v3.tar.gz && \
    chmod +x gost && \
    upx -9 gost && \
    rm -f gost_3.0.0-rc8_linux_amd64v3.tar.gz

# 创建新的用户，并切换到该用户
RUN adduser -D -u 1000 user1000
USER user1000

# 设置容器的健康检查
HEALTHCHECK --interval=2m --timeout=30s \
    CMD wget --no-verbose --tries=1 --spider ${SPACE_HOST} || exit 1

# 暴露端口
EXPOSE 7860

# 在容器内运行脚本
CMD ["/bin/bash", "/app/script.sh"]
