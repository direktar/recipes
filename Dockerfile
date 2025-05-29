FROM ruby:3.4.3

RUN apt-get update -qq && apt-get install -y \
    build-essential \
    libpq-dev \
    npm \
    postgresql-client \
    curl \
    git

RUN git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.11.3 && \
    echo '. "$HOME/.asdf/asdf.sh"' >> ~/.bashrc && \
    echo '. "$HOME/.asdf/completions/asdf.bash"' >> ~/.bashrc

RUN mkdir /app
WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

EXPOSE 3000

CMD ["bash", "-c", "rm -f tmp/pids/server.pid && bundle exec rails server -b 0.0.0.0"]
