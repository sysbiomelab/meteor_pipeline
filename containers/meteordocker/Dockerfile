FROM ubuntu:20.04
ENV TZ=Europe/Lisbon
RUN apt-get update && \
	ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
	apt-get install -y build-essential git make g++ ruby bowtie2
WORKDIR /tmp
RUN git clone --recursive https://forgemia.inra.fr/metagenopolis/meteor.git
WORKDIR meteor/meteor-pipeline/src
RUN make
RUN cp build/meteor-counter \
	build/meteor-profiler \
	../meteor.rb \
	../../data_preparation_tools/* \
	/usr/local/bin
RUN gem install inifile
