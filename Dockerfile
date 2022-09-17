##########################################
#         构建基础镜像                    #
##########################################
# 
# 指定创建的基础镜像
FROM alpine:latest

# 作者描述信息
MAINTAINER danxiaonuo
# 时区设置
ARG TZ=Asia/Shanghai
ENV TZ=$TZ
# 语言设置
ARG LANG=C.UTF-8
ENV LANG=$LANG

# 镜像变量
ARG DOCKER_IMAGE=danxiaonuo/smartdns
ENV DOCKER_IMAGE=$DOCKER_IMAGE
ARG DOCKER_IMAGE_OS=alpine
ENV DOCKER_IMAGE_OS=$DOCKER_IMAGE_OS
ARG DOCKER_IMAGE_TAG=latest
ENV DOCKER_IMAGE_TAG=$DOCKER_IMAGE_TAG

ARG PKG_DEPS="\
      zsh \
      bash \
      bind-tools \
      iproute2 \
      git \
      vim \
      tzdata \
      curl \
      wget \
      lsof \
      zip \
      unzip \
      ca-certificates"
ENV PKG_DEPS=$PKG_DEPS

# ***** 安装依赖 *****
RUN set -eux \
   # 修改源地址
   && sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories \
   # 更新源地址并更新系统软件
   && apk update && apk upgrade \
   # 安装依赖包
   && apk add -U --update $PKG_DEPS \
   # 更新时区
   && ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime \
   # 更新时间
   &&  echo ${TZ} > /etc/timezone \
   # 更改为zsh
   &&  sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || true \
   &&  sed -i -e "s/bin\/ash/bin\/zsh/" /etc/passwd \
   &&  sed -i -e 's/mouse=/mouse-=/g' /usr/share/vim/vim*/defaults.vim \
   &&  /bin/zsh

# 安装smartdns
RUN set -eux \
    && wget --no-check-certificate https://github.com/pymumu/smartdns/releases/latest/download/smartdns-x86_64 -O /usr/bin/smartdns \
    && chmod +x /usr/bin/smartdns \
    && mkdir -pv /etc/smartdns

# 设置环境变量
ENV PATH /usr/bin/smartdns:$PATH

# 拷贝smartdns配置文件
COPY conf/smartdns/smartdns.conf /etc/smartdns/smartdns.conf

# 容器信号处理
STOPSIGNAL SIGQUIT

# 运行smartdns
CMD ["smartdns", "-f", "-c", "/etc/smartdns/smartdns.conf"]
