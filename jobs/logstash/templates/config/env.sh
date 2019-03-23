#!/bin/bash
export ES_HOSTS=`cat /var/vcap/jobs/logstash/config/elasticsearch-hosts`
export ES_USERNAME=""
export ES_PASSWORD=""
<% if_p('elasticsearch.username') do |username| %>
export ES_USERNAME="<%= username %>"
<% end %>
<% if_p('elasticsearch.password') do |password| %>
export ES_PASSWORD="<%= password %>"
<% end %>
JVM_HEAP_SIZE=$((( $( cat /proc/meminfo | grep MemTotal | awk '{ print $2 }' ) * <%= p("logstash.jvm.heap_size_pct") %> ) / 100 / 1024 ))m
<% if_p('logstash.jvm.heap_size') do |heap_size| %>
JVM_HEAP_SIZE=<%= heap_size %>
<% end %>
export LS_JAVA_OPTS="-Xms$JVM_HEAP_SIZE -Xmx$JVM_HEAP_SIZE"
<% p("logstash.env", {}).each do | k, v | %>
export <%= k %>="<%= v %>"
<% end %>