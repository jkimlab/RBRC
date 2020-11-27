FROM ubuntu:16.04

RUN apt-get update && apt-get install -y \
		perl \
		python3 \
		git \
		cpanminus \
		gcc \
		g++ \
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
		curl \
		wget \
		vim

RUN cpanm \
				Sort::Key::Natural \
				Bio::TreeIO \
				Parallel::ForkManager \
				Switch


RUN git clone https://github.com/jkimlab/RBRC \
		&& cd RBRC \
		&& ./setup.pl --install \
		&& ./setup.pl --example \
		&& PATH=$PATH:/RBRC/bin
