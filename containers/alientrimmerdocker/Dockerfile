FROM ubuntu:20.04
ENV TZ=Europe/Lisbon
RUN apt-get update && \
	ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
	apt-get install -y build-essential git openjdk-11-jdk
WORKDIR /tmp
RUN git clone --recursive https://gitlab.pasteur.fr/GIPhy/AlienTrimmer.git
WORKDIR AlienTrimmer/src
RUN javac AlienTrimmer.java
RUN echo Main-Class: AlienTrimmer > MANIFEST.MF
RUN jar -cmvf MANIFEST.MF AlienTrimmer.jar AlienTrimmer.class
RUN rm MANIFEST.MF AlienTrimmer.class
RUN cp AlienTrimmer.jar /usr/local/bin
