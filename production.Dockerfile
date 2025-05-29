FROM ruby:3.4.3-alpine AS builder

ENV LANG=C.UTF-8 \
    BUNDLE_JOBS=4 \
    BUNDLE_RETRY=3 \
    RAILS_ENV=production

RUN apk add --no-cache \
    build-base \
    postgresql-dev \
    git \
    curl \
    yaml-dev \
    vips-dev \
    tzdata \
    bash \
    nodejs \
    ca-certificates \
    libxml2-dev \
    libxslt-dev \
    pkgconfig

RUN mkdir -p /rails/public/assets

WORKDIR /app

COPY Gemfile Gemfile.lock ./

RUN gem install bundler && \
    gem install nokogiri --platform=ruby && \
    bundle config set --local without 'development test' && \
    bundle install --jobs=$BUNDLE_JOBS --retry=$BUNDLE_RETRY

COPY . .

ENV SECRET_KEY_BASE=dummy

RUN bundle exec rails assets:precompile

FROM ruby:3.4.3-alpine

RUN apk add --no-cache \
    postgresql-dev \
    vips \
    yaml \
    procps \
    curl \
    git \
    ca-certificates \
    tzdata \
    bash \
    nodejs \
    libxml2 \
    libxslt \
    shadow

RUN mkdir -p /rails/public/assets

WORKDIR /app

COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY --from=builder /app /app

RUN addgroup -g 1000 appuser && \
    adduser -D -u 1000 -G appuser appuser

RUN chown -R appuser:appuser /app

USER appuser

CMD ["bundle", "exec", "rails", "server", "-e", "production", "-b", "0.0.0.0"]
