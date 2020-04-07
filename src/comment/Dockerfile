FROM ruby:2.5-alpine

WORKDIR /app

COPY Gemfile* $APP_HOME/
RUN apk --no-cache --update add build-base=0.5-r1 \
    && bundle install \
    && apk del build-base \
    && rm -rf /root/.bundle

COPY . /app

ENV COMMENT_DATABASE_HOST comment_db
ENV COMMENT_DATABASE comments

CMD ["puma"]
