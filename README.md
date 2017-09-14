# JavaOne 2017 CON3214 #
# Reactive Microservices with JRuby and Docker #
This is application demonstrates how to build reactive micro-services using JRuby, Ratpack and Docker.

## Purpose ##
Monitor weather reports and send alert messages when current conditions meet specified criteria, e.g. temperature.

## Quick start ##
### Docker compose ###
1. `docker build . -t weatheralarm`
2. `docker-compose up`
3. `export WA_WEATHER_SERVICE_URL=http://localhost:5000; ruby weather_driver/run.rb`
### Docker swarm ###
1. `docker build . -t weatheralarm`
2. `docker stack deploy --compose-file=docker-compose.yml wa`
3. `export WA_WEATHER_SERVICE_URL=http://localhost:5000; ruby weather_driver/run.rb`