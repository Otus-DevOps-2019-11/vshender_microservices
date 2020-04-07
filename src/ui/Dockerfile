FROM ruby:2.5-alpine

WORKDIR /app

COPY Gemfile* $APP_HOME/
RUN apk --no-cache --update add build-base=0.5-r1 \
    && bundle install \
    && apk del build-base \
    && rm -rf /root/.bundle

COPY . /app

ENV POST_SERVICE_HOST post
ENV POST_SERVICE_PORT 5000
ENV COMMENT_SERVICE_HOST comment
ENV COMMENT_SERVICE_PORT 9292

CMD ["puma"]
