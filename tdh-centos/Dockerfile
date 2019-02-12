FROM centos:7
ENV home /root
ENV container docker

WORKDIR /root/bootstrap

RUN (cd /lib/systemd/system/sysinit.target.wants/; \
        for i in *; do [ $i == systemd-tmpfiles-setup.service ] || rm -f $i; done); \
        rm -f /lib/systemd/system/multi-user.target.wants/*; \
        rm -f /etc/systemd/system/*.wants/*; \
        rm -f /lib/systemd/system/local-fs.target.wants/*; \
        rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
        rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
        rm -f /lib/systemd/system/basic.target.wants/*; \
        rm -f /lib/systemd/system/anaconda.target.wants/*;

RUN set -ex; \
        yum update -y; \
        yum install -y \
        screen \
        bzip2 \
        unzip \
        wget \
        rsync \
        traceroute \
        vim-enhanced \
        iproute \
        net-tools \
        bind-utils \
        openssh-server \
        patch \
        file \
        time \
        ntp \
        tcpdump \
        sudo \
        ; \
        rm -rf /var/lib/apt/lists/*

#mysql-connector-java.noarch \
#COPY jdk-8u201-linux-x64.tar.gz /root/bootstrap/
#COPY jce_policy-8.zip /root/bootstrap/

RUN set -ex; \
        wget -c --header "Cookie: oraclelicense=accept-securebackup-cookie" https://download.oracle.com/otn-pub/java/jdk/8u201-b09/42970487e3af4f5aa5bca3f542482c60/jdk-8u201-linux-x64.tar.gz; \
        mkdir -p /usr/java; \
        tar -zxf jdk-8u201-linux-x64.tar.gz -C /usr/java; \
        ln -s /usr/lib/jvm/jdk1.8.0_201 /usr/java/default; \
        rm -f jdk-8u201-linux-x64.tar.gz; \
        wget -c --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jce/8/jce_policy-8.zip; \
        unzip jce_policy-8.zip; \
        cp UnlimitedJCEPolicyJDK8/*.jar /usr/java/jdk1.8.0_201/jre/lib/security/; \
        rm -rf UnlimitedJCEPolicyJDK8 jce_policy-8.zip

RUN set -ex; \
        useradd -g users -G root,adm,tcpdump -m tca; \
        sudo -u tca ssh-keygen -q -P '' -t rsa -b 2048 -f /home/tca/.ssh/id_rsa

ADD ssh /home/tca/.ssh/
ADD ./etc /etc/
EXPOSE 22/tcp

CMD ["/usr/sbin/init"]
