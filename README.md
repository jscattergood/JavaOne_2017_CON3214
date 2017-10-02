# JavaOne 2017 CON3214 #
# Reactive Microservices with JRuby and Docker #
This is application demonstrates how to build reactive micro-services using JRuby, Ratpack and Docker.

## Purpose ##
Monitor stock prices and send alerts when prices meet specified criteria.

## Disclaimer ##
This is an example system! The purpose is to teach and therefore keeping all the code within the 
same context is beneficial. In practice, it is an anti-pattern to build multiple services from the 
same repo and docker image.

## Quick start ##
### Docker compose ###
1. `docker build . -t stockalert`
2. `docker-compose up`
3. `export SA_STOCK_SERVICE_URL=http://localhost:5000; ruby stock_driver/run.rb`
### Docker swarm ###
1. `docker build . -t stockalert`
2. `docker stack deploy --compose-file=docker-compose.yml sa`
3. `export SA_STOCK_SERVICE_URL=http://localhost:5000; ruby stock_driver/run.rb`