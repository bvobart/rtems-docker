FROM centos:8

ARG bsp=erc32
ARG builder=rtems-sparc
ARG target=sparc-rtems5
ARG tests=no

WORKDIR /workspace
VOLUME /workspace/app

ENV PREFIX=/workspace/rtems/5
ENV BSP=$bsp
ENV BUILDER=rtems-sparc
ENV TARGET=$target

RUN echo " ===> Setting up dependencies..." \
  && dnf install -y yum-utils \
  && dnf config-manager --set-enabled PowerTools \
  && dnf update -y \
  && dnf groupinstall -y "Development Tools" \
  && dnf install -y git curl python3 python3-pip python3-setuptools python3-devel texinfo spax \
  && alternatives --set python /usr/bin/python3 \
  && dnf clean all

RUN echo " ===> Downloading RTEMS sources..." \
  && git clone --depth 1 git://git.rtems.org/rtems-source-builder.git rsb \
  && git clone --depth 1 git://git.rtems.org/rtems.git

RUN echo " ===> Setting up source builder $BUILDER..." \
  && cd rsb/rtems \
  && ../source-builder/sb-set-builder --prefix=$PREFIX 5/$BUILDER \
  && cd $PREFIX/bin \
  && curl https://waf.io/waf-2.0.19 > waf \
  && chmod +x waf \
  && git clone --depth 1 git://git.rtems.org/rtems_waf.git

ENV PATH="$PREFIX/bin:$PATH"

RUN echo " ===> Bootstrapping kernel..." \
  && cd rtems \
  && ./rtems-bootstrap

RUN echo " ===> Building BSP $BSP for target $TARGET..." \
  && cd rsb/rtems \
  && ../source-builder/sb-set-builder --prefix=$PREFIX --target=$TARGET --with-rtems-bsp=$BSP --with-rtems-tests=$tests 5/rtems-kernel \
  && echo " ===> Done! Mount the folder containing your code projects to the /workspace/app folder in this container."

CMD /bin/bash
