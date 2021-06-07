#!/usr/bin/env ruby
# frozen_string_literal: true

require 'pstore'

CACHE_FILE = "#{ENV['HOME']}/.cs_cache"

cache = PStore.new(CACHE_FILE)
cache.transaction(true) do
  cache.roots.each do |key|
    value = cache[key]
    printf("%<key>-13s =>   %<value>s\n", key: key, value: value)
  end
end
