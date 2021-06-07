#!/usr/bin/env ruby
# frozen_string_literal: true

CACHE_FILE = "#{ENV['HOME']}/.cs_cache"

File.open(CACHE_FILE) do |file|
  @cache = Marshal.load(file)
end

@cache.each do |key, value|
  printf("%-13s =>   %s\n", key, value)
end
