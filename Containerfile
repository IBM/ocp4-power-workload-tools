FROM quay.io/centos/centos:stream9
RUN sed -i "s|enabled=1|enabled=0|g" /etc/yum.repos.d/centos.repo \
    && sed -i "s|enabled=1|enabled=0|g" /etc/yum.repos.d/centos-addons.repo
RUN echo -e "\
[9-stream]\n\
name=Facebook Mirror - 9 BaseOS\n\
baseurl=https://mirror.facebook.net/centos-stream/9-stream/BaseOS/ppc64le/os/\n\
enabled=1\n\
gpgcheck=0\
" > /etc/yum.repos.d/centos-stream9.repo
RUN echo -e "\
[9-stream-app]\n\
name=Facebook Mirror - 9 AppStream\n\
baseurl=https://mirror.facebook.net/centos-stream/9-stream/AppStream/ppc64le/os/\n\
enabled=1\n\
gpgcheck=0\
" > /etc/yum.repos.d/centos-stream9-app.repo
RUN cat /etc/yum.repos.d/centos-stream9.repo
RUN dnf update -y
RUN dnf install -y numactl util-linux numactl-libs powerpc-utils