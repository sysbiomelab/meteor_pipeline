FROM ubuntu:20.04
ENV TZ=Europe/Lisbon
RUN apt-get update && \
	ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
	apt-get install -y build-essential r-base
RUN Rscript -e "install.packages(pkgs = c('momr', 'dplyr'), repos = 'http://cran.us.r-project.org')"
