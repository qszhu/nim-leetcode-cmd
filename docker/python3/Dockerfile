FROM python:3.11-alpine

COPY requirements.txt .
RUN pip install -r requirements.txt
WORKDIR /usr/app
COPY precompiled precompiled