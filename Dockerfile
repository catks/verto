FROM ruby:2.6.5-alpine

# TODO: Use multi-stage builds
ENV BUILD_PACKAGES git build-base

RUN apk update && \
    apk upgrade && \
    apk add $BUILD_PACKAGES && \
    rm -rf /var/cache/apk/*

WORKDIR /usr/src/verto

COPY verto.gemspec Gemfile Gemfile.lock ./

COPY lib/verto/version.rb lib/verto/version.rb

RUN gem install bundler -v 2.0.2

RUN bundle install

COPY . .

RUN rake install

WORKDIR /usr/src/project

ENTRYPOINT ["verto"]
