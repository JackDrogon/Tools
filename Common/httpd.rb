#!/usr/bin/env ruby
# -*- coding:utf-8 -*-

require 'webrick'
include WEBrick

http = HTTPServer.new(
  :DocumentRoot => "./",
  :BindAddress => '127.0.0.1',
  :Port => 8080
)

trap("INT") {
  http.shutdown
}

http.start
