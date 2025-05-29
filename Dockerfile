FROM ruby:3.4.3

# Встановлення необхідних системних залежностей
RUN apt-get update -qq && apt-get install -y \
    build-essential \
    libpq-dev \
    nodejs \
    npm \
    postgresql-client \
    curl \
    git

# Встановлення yarn
RUN npm install -g yarn

# Встановлення asdf - для підтримки версійності
RUN git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.11.3 && \
    echo '. "$HOME/.asdf/asdf.sh"' >> ~/.bashrc && \
    echo '. "$HOME/.asdf/completions/asdf.bash"' >> ~/.bashrc

# Створення та налаштування робочої директорії
RUN mkdir /app
WORKDIR /app

# Копіювання Gemfile та інсталяція залежностей
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Копіювання всього проекту
COPY . .

# Встановлення порту для додатку
EXPOSE 3000

# Команда для запуску додатку
CMD ["bash", "-c", "rm -f tmp/pids/server.pid && bundle exec rails server -b 0.0.0.0"]
