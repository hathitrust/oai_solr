FROM ruby:3.1
ARG UNAME=app
ARG UID=1000
ARG GID=1000

RUN apt-get update -yqq && apt-get install -yqq --no-install-recommends \
  libxerces-c-samples \
  netcat

# COPY Gemfile* /usr/src/app/
WORKDIR /usr/src/app
#
ENV BUNDLE_PATH /gems
#
RUN gem install bundler

COPY --from=ghcr.io/hathitrust/feed /usr/local/feed/bin/validateCache /usr/local/bin/validateCache
#
# COPY . /usr/src/app

