#!/bin/bash
<% p("logstash.env", {}).each do | k, v | %>
export <%= k %>="<%= v %>"
<% end %>