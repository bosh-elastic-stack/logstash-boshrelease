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
<% p("logstash.env", {}).each do | k, v | %>
export <%= k %>="<%= v %>"
<% end %>