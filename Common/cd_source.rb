#!/usr/bin/env ruby

# TODO: Parallel... ThreadPool
# TODO: Add list all history
# TODO: Add auto complete
# TODO: Add List
# TODO: Use thor or opt_parse
# TODO: Use LevelDB???
# TODO: Add level command param
# TODO: 增加一个从command param的入口类
# TODO: search_dir not recursive

require 'thor'

CACHE_FILE = "#{ENV['HOME']}/.cs_cache"
SOURCE_DIR = "#{ENV['HOME']}/Source"
GITHUB_SOURCE_DIR = "#{ENV['HOME']}/Source/Github"
MAX_LEVEL = 6

HELP_INFO  = <<END
--delete key
--set key dir
--help/-h
END

IGNORE_FILEEXTENSIONS = [".c", ".cc", ".cpp", ".h", ".hpp"]


class CDSource
  DirOrFile = Struct.new(:name, :level)

  def initialize(cache_file, dir, src, level)
    @cache_file, @dir, @src, @max_level, @cache = cache_file, dir, src, level, {}
    if File.exist? cache_file
      File.open(@cache_file) do |file|
        @cache = Marshal.load(file)
      end
    end
  end

  def is_git?(dir)
    Dir.exist? "#{dir}/.git"
  end

  def is_7z?(file)
    File.exist?(file) && ! Dir.exist?(file)
  end

  def dump
    File.open(@cache_file, "w+") do |file|
      Marshal.dump(@cache, file)
    end
  end

  def set(key, value)
    @cache[key] = value
    dump
  end

  def delete(key)
    @cache.delete(key)
    dump
  end

  def search
    return if search_cache
    search_dir
  end

  def search_cache
    if @cache[@src] and File.exist? @cache[@src]
      puts @cache[@src]
      return true
    else
      @cache.delete(@src)
      return false
    end
  end

  def search_dir
    dirs = [DirOrFile.new(@dir, 1)]

    while !dirs.empty?
      d = dirs.shift
      # puts d
      next if d.level > @max_level

      name = d.name.split("/").last
      # if name == src_7z || name == src
      if name =~ /^#{@src}((\.|(-[0-9]+)).*)?$/
        # puts src, "name", /^#{src}((\.|-?).*)?$/
        if not IGNORE_FILEEXTENSIONS.include? $1 # 应该主动识别是不是压缩文件
          dump
          puts d.name
          return
        end
      end

      next if ! Dir.exist? d.name

      if is_git?(d.name)
        if name == @src
          puts d.name
          return
        end
      else
        Dir["#{d.name}/*"].each{|dir| dirs << DirOrFile.new(dir, d.level+1)}
      end
    end
  end
end

class CDSourceCLI < Thor
end

def main()
  if ARGV[0] == "--delete"
    cd_source = CDSource.new CACHE_FILE, SOURCE_DIR, nil, MAX_LEVEL
    cd_source.delete(ARGV[1])
    return
  elsif ARGV[0] == "--set"
    cd_source = CDSource.new CACHE_FILE, SOURCE_DIR, nil, MAX_LEVEL
    cd_source.set(ARGV[1], ARGV[2])
    return
  elsif ARGV[0] == "--help" || ARGV[0] == "-h"
    puts HELP_INFO
    exit 1
  end

  cd_source = CDSource.new CACHE_FILE, SOURCE_DIR, ARGV[0], MAX_LEVEL
  cd_source.search()
  # cd_source_ GithubSourceDir, @src, 0
end

trap(:INT) { puts "Exit ..."; exit(1); }

if $0 == __FILE__
  main
end
