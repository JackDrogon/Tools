#!/usr/bin/env ruby
require 'webrick'
include WEBrick

http = HTTPServer.new(
  DocumentRoot: './',
  BindAddress: '127.0.0.1',
  Port: 8080
)

trap('INT') do
  http.shutdown
end

http.start
