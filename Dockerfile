FROM continuumio/anaconda3:2022.10
LABEL "author"="Mathieu Fourment"
LABEL "company"="University of Technology Sydney"

RUN apt-get update && \
	apt-get install -y --no-install-recommends \
		ant \
		autoconf \
		automake \
		build-essential \
		cmake \
		default-jdk \
		git \
		libgsl0-dev \
		libtool \
		pkg-config \
		unzip \
		wget \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/beagle-dev/beagle-lib.git /beagle-lib
RUN git -C /beagle-lib checkout hmc-clock
RUN cmake -S /beagle-lib/ -B /beagle-lib/build -DBUILD_CUDA=OFF -DBUILD_OPENCL=OFF
RUN cmake --build beagle-lib/build/ --target install

RUN git clone https://github.com/4ment/beast-mcmc.git /beast-mcmc
RUN cd /beast-mcmc && git checkout torchtree-experiments && ant linux
RUN chmod +x /beast-mcmc/release/Linux/BEASTv1.10.5pre/bin/beast \
	&& ln -s /beast-mcmc/release/Linux/BEASTv1.10.5pre/bin/beast /usr/local/bin/

RUN wget https://github.com/iqtree/iqtree2/releases/download/v2.2.2.6/iqtree-2.2.2.6-Linux.tar.gz
RUN tar -xzvf iqtree-2.2.2.6-Linux.tar.gz && chmod +x /iqtree-2.2.2.6-Linux/bin/iqtree2 \
	&& ln -s /iqtree-2.2.2.6-Linux/bin/iqtree2 /usr/local/bin/

RUN wget https://github.com/tothuhien/lsd2/releases/download/v.2.3/lsd2_unix \
	&& chmod +x lsd2_unix && mv lsd2_unix /usr/local/bin/lsd2

RUN wget https://github.com/4ment/physher/archive/refs/tags/v2.0.1.tar.gz
RUN tar -xzvf v2.0.1.tar.gz
RUN cmake -S /physher-2.0.1 -B /physher-2.0.1/build -DBUILD_CPP_WRAPPER=on -DBUILD_TESTING=on
RUN cmake --build /physher-2.0.1/build/ --target install

RUN pip install torch==1.12.1 numpy==1.22 torchtree==1.0.2 \
	&& torchtree --help

ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib
ENV LIBRARY_PATH=$LIBRARY_PATH:/usr/local/lib

RUN pip install torchtree-physher==1.0.0 torchtree-scipy==1.0.0

