FROM ruby:2.5-alpine

WORKDIR /app

COPY Gemfile* $APP_HOME/
RUN apk --no-cache --update add build-base=0.5-r1 \
    && bundle install \
    && apk del build-base \
    && rm -rf /root/.bundle

COPY . /app

ENV DATABASE_URL mongodb://mongo/user_posts
EXPOSE 9292

CMD ["puma"]
