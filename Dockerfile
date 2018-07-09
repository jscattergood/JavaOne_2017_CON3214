FROM jruby:9.2.0

WORKDIR /usr/src/app

ADD Gemfile /usr/src/app/
ADD Gemfile.lock /usr/src/app/
RUN bundle install --system

ADD Jarfile /usr/src/app/
ADD Jarfile.lock /usr/src/app/
RUN jbundle install --system

ENV SA_SERVER__PORT=80

HEALTHCHECK --interval=1m --timeout=10s \
  CMD curl -f http://localhost/ || exit 1
