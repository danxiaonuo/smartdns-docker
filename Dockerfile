##########################################
#         构建基础镜像                    #
##########################################
# 
# 指定创建的基础镜像
FROM alpine:latest

# 镜像变量
ARG DOCKER_IMAGE=danxiaonuo/smartdns
ENV DOCKER_IMAGE=$DOCKER_IMAGE
ARG DOCKER_IMAGE_OS=alpine
ENV DOCKER_IMAGE_OS=$DOCKER_IMAGE_OS
ARG DOCKER_IMAGE_TAG=latest
ENV DOCKER_IMAGE_TAG=$DOCKER_IMAGE_TAG
ARG BUILD_DATE
ENV BUILD_DATE=$BUILD_DATE


# 作者描述信息
MAINTAINER danxiaonuo
# 时区设置
ARG TZ=Asia/Shanghai
ENV TZ=$TZ

ARG PKG_DEPS="\
      tzdata \
      ca-certificates"
ENV PKG_DEPS=$PKG_DEPS

# dumb-init
# https://github.com/Yelp/dumb-init
ARG DUMBINIT_VERSION=1.2.2
ENV DUMBINIT_VERSION=$DUMBINIT_VERSION

# http://label-schema.org/rc1/
LABEL maintainer="danxiaonuo <danxiaonuo@danxiaonuo.me>" \
      org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.name="$DOCKER_IMAGE" \
      org.label-schema.schema-version="1.0" \
      org.label-schema.url="https://github.com/$DOCKER_IMAGE" \
      versions.dumb-init=${DUMBINIT_VERSION}


# 修改源地址
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories
# ***** 安装依赖 *****
RUN set -eux \
   # 更新源地址
   && apk update \
   # 更新系统并更新系统软件
   && apk upgrade && apk upgrade \
   && apk add -U --update $PKG_DEPS \
   # 更新时区
   && ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime \
   # 更新时间
   && echo ${TZ} > /etc/timezone

# 安装smartdns
RUN set -eux \
    && wget --no-check-certificate https://github.com/pymumu/smartdns/releases/latest/download/smartdns-x86_64 -O /usr/bin/smartdns \
    && chmod +x /usr/bin/smartdns \
    && mkdir -pv /etc/smartdns

# 安装dumb-init
RUN set -eux \
    && wget --no-check-certificate https://github.com/Yelp/dumb-init/releases/download/v${DUMBINIT_VERSION}/dumb-init_${DUMBINIT_VERSION}_x86_64 -O /usr/bin/dumb-init \
    && chmod +x /usr/bin/dumb-init

# 设置环境变量
ENV PATH /usr/bin/smartdns:$PATH

# 拷贝smartdns配置文件
COPY conf/smartdns/smartdns.conf /etc/smartdns/smartdns.conf

# 容器信号处理
STOPSIGNAL SIGQUIT

# 入口
ENTRYPOINT ["dumb-init"]

# 运行smartdns
CMD ["/usr/bin/smartdns", "-f", "-c", "/etc/smartdns/smartdns.conf"]
