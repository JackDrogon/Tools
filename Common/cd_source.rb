#!/usr/bin/env ruby

# TODO: Parallel... ThreadPool
# TODO: Add list all history
# TODO: Add auto complete
# TODO: Use thor or opt_parse
# TODO: Use LevelDB???
# TODO: Add level command param
# TODO: 增加一个从command param的入口类
# TODO: search_dir not recursive
# TODO: purge 按照存在不存在 && level深度
# TODO: list use format
# TODO: load exception
# TODO: dump, first bak && check file
# TODO: Add log
# TODO: Add extension name check

# require 'thor'
require 'pstore'
require 'fileutils'

CACHE_FILE = "#{ENV['HOME']}/.cs_cache"
SOURCE_DIRS = ["#{ENV['HOME']}/Source", "#{ENV['HOME']}/Source/Github"]
MAX_LEVEL = 6

HELP_INFO  = <<END
--delete key
--set key dir
--list
--purge
--help/-h
END

IGNORE_FILEEXTENSIONS = [".c", ".cc", ".cpp", ".h", ".hpp"]

module Helper
  def trip_home(v)
    v.sub ENV["HOME"], "~"
  end

  def real_path(v)
    v.sub "~", ENV["HOME"]
  end

  def is_git?(dir)
    Dir.exist? "#{dir}/.git"
  end

  def is_7z?(file)
    File.exist?(file) && ! File.directory?(file)
  end
end

class CDSource
  DirOrFile = Struct.new(:name, :level)

  include Helper

  def initialize(cache_file, search_dirs, find_name, level)
    @cache_file, @find_name, @max_level = cache_file, find_name, level
    @search_dirs = Array === search_dirs ? search_dirs : [search_dirs]
    @cache = PStore.new @cache_file
  end

  def get(key)
    value=nil
    @cache.transaction(true) do
      value = @cache.fetch(key, nil)
    end
    value
  end

  def set(key, value)
    @cache.transaction do
      @cache[key] = trip_home(value)
    end
  end

  def delete(key)
    @cache.transaction do
      @cache.delete(key)
    end
  end

  def list()
    @cache.transaction(true) do
      @cache.roots.each do |k|
        puts "#{k} => #{@cache[k]}"
      end
    end
  end

  def search
    return if search_cache
    search_dir
  end

  private
  def exist(key)
    @cache.transaction(true) do
      @cache.root? key
    end
  end

  def search_cache
    if exist(@find_name)
      rpath = real_path(get(@find_name))
      if Dir.exist?(rpath) or File.exist?(rpath)
        puts rpath
        true
      else
        delete(@find_name)
        false
      end
    else
      false
    end
  end

  def search_dir
    @search_dirs.each do |sdir|
      dirs = [DirOrFile.new(sdir, 1)]

      while !dirs.empty?
        d = dirs.shift
        next if d.level > @max_level

        name = d.name.split("/").last
        # if name == src_7z || name == src
        if name =~ /^#{@find_name}((\.|(-[0-9]+)).*)?$/
          # puts src, "name", /^#{src}((\.|-?).*)?$/
          if not IGNORE_FILEEXTENSIONS.include? $1 # 应该主动识别是不是压缩文件
            set(@find_name, d.name)
            puts d.name
            return
          end
        end

        next unless File.directory? d.name

        if is_git?(d.name)
          if name == @find_name
            set(@find_name, d.name)
            puts d.name
            return
          end
        else
          Dir["#{d.name}/*"].each{|dir| dirs << DirOrFile.new(dir, d.level+1)}
        end
      end
    end
  end
end

# class CDSourceCLI < Thor
# end

def main()
  case ARGV[0]
  when "--list"
    cd_source = CDSource.new CACHE_FILE, SOURCE_DIRS, nil, MAX_LEVEL
    cd_source.list()
  when "--delete"
    cd_source = CDSource.new CACHE_FILE, SOURCE_DIRS, nil, MAX_LEVEL
    cd_source.delete(ARGV[1])
  when "--set"
    cd_source = CDSource.new CACHE_FILE, SOURCE_DIRS, nil, MAX_LEVEL
    cd_source.set(ARGV[1], ARGV[2])
  when "--help", "-h"
    puts HELP_INFO
    exit 1
  else
    cd_source = CDSource.new CACHE_FILE, SOURCE_DIRS, ARGV[0], MAX_LEVEL
    cd_source.search()
  end
end

trap(:INT) { puts "Exit ..."; exit(1); }

if $0 == __FILE__
  main
end
