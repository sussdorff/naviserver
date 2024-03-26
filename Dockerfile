FROM ubuntu:22.04

ENV version_ns 4.99.25
ENV version_tcl 8.6.14
ENV version_tcllib 1.21
ENV version_thread 2.8.9
ENV version_xotcl 2.4.0
ENV version_tdom 0.9.1

WORKDIR /usr/local/src 

RUN  export LANG=en_US.UTF-8 && export LC_ALL=en_US.UTF-8 && apt-get update && apt-get upgrade -y
RUN apt-get install -y wget gnupg apt-utils git autoconf make gcc zlib1g-dev zip unzip openssl libssl-dev libpq-dev postgresql-client locales
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends tzdata && locale-gen en_US.UTF-8 && update-locale LANG="en_US.UTF-8" && update-locale LC_ALL=en_US.UTF-8 \
	&& apt-get clean

RUN groupadd nsadmin && useradd -g nsadmin nsadmin 

RUN wget https://core.tcl-lang.org/tcl/tarball/release/tcl.tar.gz

RUN tar xfz tcl.tar.gz \
	&& cd tcl/unix \
	&& ./configure --enable-threads --prefix=/usr/local/ns \
	&& make && make install \
	&& bash -c "source /usr/local/ns/lib/tclConfig.sh" \
	&& ln -sf /usr/local/ns/bin/tclsh${version_tcl}} /usr/local/ns/bin/tclsh && cd /usr/local/src

RUN wget https://core.tcl-lang.org/tcllib/uv/tcllib-${version_tcllib}.tar.gz \
	&& tar xfz tcllib-${version_tcllib}.tar.gz \
	&& cd /usr/local/src/tcllib-${version_tcllib} \
	&& ./configure --prefix=/usr/local/ns \
	&& make install

RUN cd /usr/local/src && rm -rf tcllib* \ 
	&& git clone https://bitbucket.org/naviserver/naviserver.git \
 	&& cd /usr/local/src/naviserver \
	&& ./autogen.sh && make && make && make install \
	&& cd /usr/local/src && rm -rf naviserver* \
	&& mkdir modules && cd modules \
	&& git clone https://bitbucket.org/naviserver/nsdbpg.git \
	&& cd /usr/local/src/modules/nsdbpg \
	&& make PGLIB=/usr/lib PGINCLUDE=/usr/include/postgresql NAVISERVER=/usr/local/ns \
	&& make NAVISERVER=/usr/local/ns install \
	&& cd /usr/local/src/modules && git clone https://bitbucket.org/naviserver/nsstats.git \
	&& cd /usr/local/src/modules/nsstats \
	&& make NAVISERVER=/usr/local/ns \
	&& make NAVISERVER=/usr/local/ns install \
	&& cd /usr/local/src/modules && git clone https://bitbucket.org/naviserver/nsconf.git \
	&& cd /usr/local/src/modules/nsconf \
	&& make NAVISERVER=/usr/local/ns \
	&& make NAVISERVER=/usr/local/ns install \
	&& cd /usr/local/src && rm -rf naviserver*

RUN git clone git://alice.wu.ac.at/nsf && cd nsf \
    && ./configure --enable-threads --enable-symbols --prefix=/usr/local/ns --exec-prefix=/usr/local/ns --with-tcl=/usr/local/ns/lib \
	&& make && make install && cd /usr/local/src && rm -rf nsf* 

RUN wget --quiet http://tdom.org/downloads/tdom-${version_tdom}-src.tgz \
	&& tar zxf tdom-${version_tdom}-src.tgz \
	&& cd  /usr/local/src/tdom-${version_tdom}/unix \ 
	&& ../configure --enable-threads --disable-tdomalloc --prefix=/usr/local/ns --exec-prefix=/usr/local/ns --with-tcl=/usr/local/ns/lib \
	&& make install && cd /usr/local/src/ && rm -rf tdom* 

EXPOSE 8080

WORKDIR /usr/local/ns

ENTRYPOINT ["/usr/local/ns/bin/nsd"]
CMD ["-f", "-u","nsadmin","-g","nsadmin","-t", "/usr/local/ns/conf/nsd-config.tcl"]