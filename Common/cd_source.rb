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

# require 'thor'
require 'fileutils'

CACHE_FILE = "#{ENV['HOME']}/.cs_cache"
SOURCE_DIR = "#{ENV['HOME']}/Source"
GITHUB_SOURCE_DIR = "#{ENV['HOME']}/Source/Github"
MAX_LEVEL = 6

HELP_INFO  = <<END
--delete key
--set key dir
--list
--purge
--help/-h
END

IGNORE_FILEEXTENSIONS = [".c", ".cc", ".cpp", ".h", ".hpp"]


class CDSource
  DirOrFile = Struct.new(:name, :level)

  def initialize(cache_file, search_dir, find_name, level)
    @cache_file, @search_dir, @find_name, @max_level, @cache = cache_file, search_dir, find_name, level, {}
    if File.exist? @cache_file
      File.open(@cache_file) do |file|
        begin
          @cache = Marshal.load(file)
        rescue
          @cache = {}
        end
      end
    else
      FileUtils.touch @cache_file
    end
  end

  def set(key, value)
    @cache[key] = trip_home(value)
    dump
  end

  def delete(key)
    @cache.delete(key)
    dump
  end

  def list()
    @cache.each {|k, v| puts "#{k} => #{v}"}
  end

  def search
    return if search_cache
    search_dir
  end

  private
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

  def dump
    # check file size, ignore empty size
    FileUtils.mv @cache_file, @cache_file+".bak", :force => true
    File.open(@cache_file, "w+") do |file|
      Marshal.dump(@cache, file)
    end
    File.open(@cache_file) do |file|
      begin
        Marshal.load(file)
      rescue
        FileUtils.cp @cache_file+".bak", @cache_file, :force => true
      end
    end
  end

  def search_cache
    if @cache[@find_name]
      rpath = real_path(@cache[@find_name])
      if Dir.exist?(rpath) or File.exist?(rpath)
        puts rpath
        true
      else
        @cache.delete(@find_name)
        dump
        false
      end
    else
      false
    end
  end

  def search_dir
    dirs = [DirOrFile.new(@search_dir, 1)]

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

# class CDSourceCLI < Thor
# end

def main()
  case ARGV[0]
  when "--list"
    cd_source = CDSource.new CACHE_FILE, SOURCE_DIR, nil, MAX_LEVEL
    cd_source.list()
  when "--delete"
    cd_source = CDSource.new CACHE_FILE, SOURCE_DIR, nil, MAX_LEVEL
    cd_source.delete(ARGV[1])
  when "--set"
    cd_source = CDSource.new CACHE_FILE, SOURCE_DIR, nil, MAX_LEVEL
    cd_source.set(ARGV[1], ARGV[2])
  when "--help", "-h"
    puts HELP_INFO
    exit 1
  else
    cd_source = CDSource.new CACHE_FILE, SOURCE_DIR, ARGV[0], MAX_LEVEL
    cd_source.search()
  end

  # cd_source_ GithubSourceDir, @find_name, 0
end

trap(:INT) { puts "Exit ..."; exit(1); }

if $0 == __FILE__
  main
end
