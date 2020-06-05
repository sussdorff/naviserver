FROM ubuntu:18.04

ENV version_ns 4.99.19
ENV version_tcl 8.6.10
ENV version_tcllib 1.20
ENV version_thread 2.8.5
ENV version_xotcl 2.3.0
ENV version_tdom 0.9.1

WORKDIR /usr/local/src 

RUN  export LANG=en_US.UTF-8 && export LC_ALL=en_US.UTF-8
RUN  apt-get update && apt-get install wget gnupg apt-utils tzdata -y \
	&& apt-get install make gcc zlib1g-dev zip unzip openssl libssl-dev libpq-dev postgresql-client locales -y \
	&& locale-gen en_US.UTF-8 && update-locale LANG="en_US.UTF-8" && update-locale LC_ALL=en_US.UTF-8 \
	&& apt-get clean \
	&& groupadd nsadmin \
	&& useradd -g nsadmin nsadmin \
	&& wget --quiet https://downloads.sourceforge.net/sourceforge/tcl/tcl${version_tcl}-src.tar.gz \
	&& tar xfz tcl${version_tcl}-src.tar.gz \
	&& cd tcl${version_tcl}/unix \
	&& ./configure --enable-threads --prefix=/usr/local/ns \
	&& make && make install \
	&& bash -c "source /usr/local/ns/lib/tclConfig.sh" \
	&& ln -sf /usr/local/ns/bin/tclsh8.6.10 /usr/local/ns/bin/tclsh && cd /usr/local/src \
	&& wget --quiet https://downloads.sourceforge.net/sourceforge/tcllib/tcllib-${version_tcllib}.tar.bz2 \
	&& tar xfj tcllib-${version_tcllib}.tar.bz2 \
	&& cd /usr/local/src/tcllib-${version_tcllib} \
	&& ./configure --prefix=/usr/local/ns \
	&& make install \
	&& cd /usr/local/src && rm -rf tcllib* \
	&& wget --quiet https://downloads.sourceforge.net/sourceforge/naviserver/naviserver-${version_ns}.tar.gz \
	&& tar zxvf naviserver-${version_ns}.tar.gz \
	&& cd /usr/local/src/naviserver-${version_ns} \
	&& ./configure --with-tcl=/usr/local/ns/lib --prefix=/usr/local/ns \
	&& make && make install \
	&& cd /usr/local/src && rm -rf naviserver* \
	&& wget --quiet https://downloads.sourceforge.net/sourceforge/naviserver/naviserver-${version_ns}-modules.tar.gz \
	&& tar zxvf naviserver-${version_ns}-modules.tar.gz \
	&& cd /usr/local/src/modules/nsdbpg \
	&& make PGLIB=/usr/lib PGINCLUDE=/usr/include/postgresql NAVISERVER=/usr/local/ns \
	&& make NAVISERVER=/usr/local/ns install \
	&& cd /usr/local/src/modules/nsstats \
	&& make NAVISERVER=/usr/local/ns \
	&& make NAVISERVER=/usr/local/ns install \
	&& cd /usr/local/src/modules/nsconf \
	&& make NAVISERVER=/usr/local/ns \
	&& make NAVISERVER=/usr/local/ns install \
	&& cd /usr/local/src && rm -rf naviserver* \
	&& wget --quiet https://downloads.sourceforge.net/sourceforge/tcl/thread${version_thread}.tar.gz \
	&& tar xfz thread${version_thread}.tar.gz \
	&& cd /usr/local/src/thread${version_thread}/unix/ \
	&& ../configure --enable-threads --prefix=/usr/local/ns --exec-prefix=/usr/local/ns \
		--with-naviserver=/usr/local/ns --with-tcl=/usr/local/ns/lib \
	&& make && make install \
	&& cd /usr/local/src && rm -rf thread${version_thread}* \
	&& wget --quiet https://downloads.sourceforge.net/sourceforge/next-scripting/nsf${version_xotcl}.tar.gz \
	&& tar xvfz nsf${version_xotcl}.tar.gz && cd nsf${version_xotcl} \
    && ./configure --enable-threads --enable-symbols --prefix=/usr/local/ns --exec-prefix=/usr/local/ns --with-tcl=/usr/local/ns/lib \
	&& make && make install && cd /usr/local/src && rm -rf nsf* \
	&& wget --quiet http://tdom.org/downloads/tdom-${version_tdom}-src.tgz \
	&& tar zxf tdom-${version_tdom}-src.tgz \
	&& cd  /usr/local/src/tdom-${version_tdom}/unix \ 
	&& ../configure --enable-threads --disable-tdomalloc --prefix=/usr/local/ns --exec-prefix=/usr/local/ns --with-tcl=/usr/local/ns/lib \
	&& make install && cd /usr/local/src/ && rm -rf tdom* \
	&& wget --quiet https://github.com/RubyLane/rl_json/archive/master.zip && unzip master.zip && cd rl_json-master && ./configure --prefix=/usr/local/ns && make && make install && cd /usr/local/src/ \
	&& chgrp -R nsadmin /usr/local/ns && chmod -R g+w /usr/local/ns \
	&& rm -rf /usr/local/src/* \
	&& apt-get remove libssl-dev gnupg apt-utils -y && apt-get auto-remove -y \
	&& rm -rf /tmp/* /var/lib/apt/lists/* /var/cache/apt/*

EXPOSE 8080

WORKDIR /usr/local/ns

ENTRYPOINT ["/usr/local/ns/bin/nsd"]
CMD ["-f", "-u","nsadmin","-g","nsadmin","-t", "/usr/local/ns/conf/nsd-config.tcl"]