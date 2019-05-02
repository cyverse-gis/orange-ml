FROM consol/ubuntu-xfce-vnc

USER root

# conda install requires bzip
RUN apt-get update && apt-get install -y python3-pip python3-dev python-virtualenv bzip2 g++ git
RUN apt-get install -y xfce4-terminal software-properties-common python-numpy
# RUN apt-get install -y sudo

# browsers
RUN rm /usr/share/xfce4/helpers/debian-sensible-browser.desktop
RUN add-apt-repository --yes ppa:jonathonf/firefox-esr && apt-get update
RUN apt-get remove -y --purge firefox && apt-get install -y firefox-esr

ENV USER orange
ENV PASSWORD orange
ENV HOME /home/${USER}
ENV CONDA_DIR /home/${USER}/.conda

RUN useradd -m -s /bin/bash ${USER}
RUN echo "${USER}:${PASSWORD}" | chpasswd
# RUN gpasswd -a ${USER} sudo

USER orange
WORKDIR ${HOME}

RUN wget -q https://repo.continuum.io/archive/Anaconda3-5.3.1-Linux-x86_64.sh -O anaconda.sh
RUN bash anaconda.sh -b -p ~/.conda && rm anaconda.sh
RUN $CONDA_DIR/bin/conda create python=3.6 --name orange3
RUN $CONDA_DIR/bin/conda config --add channels conda-forge
RUN bash -c "source $CONDA_DIR/bin/activate orange3 && $CONDA_DIR/bin/conda install orange3"
RUN echo 'export PATH=~/.conda/bin:$PATH' >> /home/orange/.bashrc
RUN bash -c "source $CONDA_DIR/bin/activate orange3 && pip install Orange3-Text Orange3-ImageAnalytics Orange3-Network Orange-Bioinformatics"

ADD ./icons/orange.png /usr/share/backgrounds/images/orange.png
ADD ./icons/orange.png .conda/share/orange3/orange.png
ADD ./orange/orange-canvas.desktop Desktop/orange-canvas.desktop
ADD ./config/xfce4 .config/xfce4
ADD ./install/chromium-wrapper install/chromium-wrapper

RUN wget -qO - https://packages.irods.org/irods-signing-key.asc | apt-key add - \
    && echo "deb [arch=amd64] https://packages.irods.org/apt/ xenial main" > /etc/apt/sources.list.d/renci-irods.list \
    && apt-get update \
	  && apt-get install -y irods-icommands

USER root
RUN chown -R orange:orange .config Desktop install

ADD ./install/vnc_startup.sh /dockerstartup/vnc_startup.sh
RUN chmod a+x /dockerstartup/vnc_startup.sh

USER orange

# Prepare for external settings volume
RUN mkdir .config/biolab.si

ENV VNC_RESOLUTION 1920x1080
ENV VNC_PW orange

RUN cp /headless/wm_startup.sh ${HOME}

ENTRYPOINT ["/dockerstartup/vnc_startup.sh"]
CMD ["--tail-log"]
