# fast-elk

Beta Cookbook

Basic fast uncomplicated ELK rollout and reference

For the moment this is Ubuntu only.

## Recipes
install\_elasticsearch\_logstash = install Elasticsearch, nginx, Logstash, Kibana

java = does java!

nxlog = install nxlog for piping in logs to logstash

nxlog\_windows = sets up reference nxlog for 64bit windows (eventvwr and iis)

default = calls install

## One way to call this
berks vendor /tmp/elk/cookbooks/

cd /tmp/elk

sudo chef-client -l error -z -o fast-elk::install\_elasticsearch\_logstash,fast-elk::nxlog



##TODO
Add more support for more OS's

Add AWS clustering

Add S3 buckets for ELB logs

Add cloudwatch - https://github.com/EagerELK/logstash-input-cloudwatch

Add Kibana ACL - e.g Shield or Search Guard

Output to Graphite

Add support for nightly index chop to backup 
