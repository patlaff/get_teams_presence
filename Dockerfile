# syntax=docker/dockerfile:1

FROM python:3.10-buster

WORKDIR /gtp

ENV VIRTUAL_ENV=/opt/venv
RUN python3 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

RUN cd $VIRTUAL_ENV
RUN git clone https://github.com/RPi-Distro/RTIMULib/ RTIMU
RUN cd RTIMU/Linux/python
RUN sudo apt install python3-dev
RUN python setup.py build && python setup.py install
RUN sudo apt install libopenjp2-7

COPY . .
RUN pip3 install -r requirements.txt

CMD ["python3", "get_msgraph_presence.py"]