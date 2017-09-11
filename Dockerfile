FROM jruby:9.1.13

WORKDIR /usr/src/app

ADD Gemfile /usr/src/app/
ADD Gemfile.lock /usr/src/app/
RUN bundle install --system

ADD Jarfile /usr/src/app/
ADD Jarfile.lock /usr/src/app/
RUN jbundle install --system

ENV WA_SERVER__PORT=80