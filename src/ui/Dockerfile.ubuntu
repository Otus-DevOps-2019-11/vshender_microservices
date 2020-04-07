FROM ubuntu:16.04

RUN apt-get update \
    && apt-get install --no-install-recommends -y ruby-full=1:2.3.0+1 ruby-dev=1:2.3.0+1 build-essential=12.1ubuntu2 \
    && rm -rf /var/lib/apt/lists/* \
    && gem install bundler:2.1.4 --no-ri --no-rdoc

ENV APP_HOME /app
RUN mkdir $APP_HOME
WORKDIR $APP_HOME

COPY Gemfile* $APP_HOME/
RUN bundle install
COPY . $APP_HOME

ENV POST_SERVICE_HOST post
ENV POST_SERVICE_PORT 5000
ENV COMMENT_SERVICE_HOST comment
ENV COMMENT_SERVICE_PORT 9292

CMD ["puma"]
