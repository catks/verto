FROM ruby:2.6.5-alpine AS builder

ENV BUILD_PACKAGES build-base git

RUN mkdir /bundle

RUN apk update && \
    apk upgrade && \
    apk add $BUILD_PACKAGES && \
    rm -rf /var/cache/apk/*

COPY verto.gemspec Gemfile Gemfile.lock ./

COPY lib/verto/version.rb lib/verto/version.rb

RUN gem install bundler -v 2.0.2

RUN bundle install

FROM ruby:2.6.5-alpine

ENV DEPENDENCIES git

RUN apk update && \
    apk upgrade && \
    apk add $DEPENDENCIES && \
    rm -rf /var/cache/apk/*

WORKDIR /usr/src/verto

COPY --from=builder /usr/local/bundle/ /usr/local/bundle

RUN gem install bundler -v 2.0.2

COPY . .

RUN rake install

WORKDIR /usr/src/project

ENTRYPOINT ["verto"]
