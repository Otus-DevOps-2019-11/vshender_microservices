FROM python:3.6.0-alpine

WORKDIR /app

COPY requirements.txt /app
RUN apk --no-cache --update add build-base=0.4-r1 \
    && pip install -r /app/requirements.txt \
    && apk del build-base \
    && rm -rf /root/.cache

COPY . /app

ENV POST_DATABASE_HOST post_db
ENV POST_DATABASE posts

CMD ["python3", "post_app.py"]
