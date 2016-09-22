FROM ruby:2.3.1

RUN apt-get update && apt-get install -qq -y build-essential libgeos-dev --fix-missing --no-install-recommends

ENV INSTALL_PATH /geo_pointer
RUN mkdir -p $INSTALL_PATH
WORKDIR $INSTALL_PATH
COPY . .
RUN gem install bundler
RUN bundle install -j10
RUN gem install puma
ENTRYPOINT cd $INSTALL_PATH && puma -t 4:8 -w 4 --preload
