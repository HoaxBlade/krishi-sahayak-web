FROM tensorflow/tensorflow:2.20.0

WORKDIR /app

ENV PYTHONUNBUFFERED=1

COPY requirements.txt /app
RUN pip install --upgrade pip && pip install --default-timeout=1000 -r requirements.txt

COPY .env /app
COPY . /app

EXPOSE 8000

CMD gunicorn --bind 0.0.0.0:8000 main:app
