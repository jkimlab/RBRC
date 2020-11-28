FROM ubuntu:16.04

RUN apt-get update && apt-get install -y \
	perl \
	python3 \
	git \
	gcc \
	g++ \
	cpanminus \
	build-essential \
	pkg-config \
	libgd-dev \
	libncurses-dev \
	libghc-bzlib-dev \
	libboost-all-dev \
	build-essential \
	libz-dev \
	openjdk-8-jdk \
	openjdk-8-jre \
	make \
	zip \
	wget \
	vim

RUN apt-get update -y && \
	apt-get upgrade -y && \
	apt-get dist-upgrade -y && \
	apt-get install build-essential software-properties-common -y && \
	add-apt-repository ppa:ubuntu-toolchain-r/test -y && \
	apt-get update -y && \
	apt-get install gcc-7 g++-7 -y && \
	update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-7 60 --slave /usr/bin/g++ g++ /usr/bin/g++-7 && \
	update-alternatives --config gcc

RUN cpanm \
	Sort::Key::Natural \
	Bio::TreeIO \
	Parallel::ForkManager \
	Switch

RUN git clone https://github.com/jkimlab/RBRC \
	&& cd RBRC \
	&& ./setup.pl --install \
	&& ./setup.pl --example \
	&& cp ./bin/* /bin/
