#!/usr/bin/env -S ruby --jit

# TODO: Parallel... ThreadPool
# TODO: Add list all history
# TODO: Add auto complete
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

require 'pstore'
require 'fileutils'
require 'optparse'

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
  DirOrFile = Struct.new(:name, :depth)

  include Helper

  def initialize(cache_file, search_dirs, repo, max_level)
    repo, @max_level = repo, max_level
    @search_dirs = (Array === search_dirs) ? search_dirs : [search_dirs]
    @cache = PStore.new(cache_file)
  end

  def get(key)
    value = nil
    @cache.transaction(true) do
      value = @cache.fetch(key, nil)
    end
    value
  end

  def put(key, value)
    @cache.transaction do
      @cache[key] = trip_home(value)
    end
  end

  def delete(key)
    @cache.transaction do
      @cache.delete(key)
    end
  end

  def list
    @cache.transaction(true) do
      @cache.roots.each do |k|
        puts "#{k} => #{@cache[k]}"
      end
    end
  end

  def search(repo)
    return if _search_cache(repo)
    _search_dir repo
  end

  def purge
    @cache.transaction do
      @cache.roots.each do |k|
        path = @cache[k]
        if path == nil
          @cache.delete(k)
          next
        end

        rpath = real_path(path)
        # File exist check compress file
        if not Dir.exist?(rpath) and not File.exist?(rpath)
          @cache.delete(k)
        end
      end
    end
  end

  private
  def _exist(key)
    @cache.transaction(true) do
      @cache.root? key
    end
  end

  def _search_cache(repo)
    unless _exist(repo)
      return false
    end

    rpath = real_path(get(repo))
    if Dir.exist?(rpath) or File.exist?(rpath)
      puts rpath
      true
    else
      delete(repo)
      false
    end
  end

  def _search_dir(repo)
    @search_dirs.each do |sdir|
      dirs = [DirOrFile.new(sdir, 1)]

      # BFS search dir and file
      # Rules
      # 1.1 depth > max_level skip
      # file/dir
      # dir:
      #  if not git, add all sub dir
      # file: if 7z, skip
      while !dirs.empty?
        d = dirs.shift
        next if d.depth > @max_level

        name = d.name.split("/").last
        # if name == src_7z || name == src
        if name =~ /^#{repo}((\.|(-[0-9]+)).*)?$/
          # puts src, "name", /^#{src}((\.|-?).*)?$/
          if not IGNORE_FILEEXTENSIONS.include? $1 # 应该主动识别是不是压缩文件
            put(repo, d.name)
            puts d.name
            return
          end
        end

        # if not dir just file, skip
        next unless File.directory? d.name

        # now d is dir
        # if not git, add all sub dir
        if !is_git?(d.name)
          Dir["#{d.name}/*"].each{|dir| dirs << DirOrFile.new(dir, d.depth+1)}
          next
        end

        # if git, search all file
        if name == repo
          put(repo, d.name)
          puts d.name
          return
        end
      end
    end
  end
end

def main()
  # Use OptionParser rewrite
  options = {}
  option_parser = OptionParser.new do |opts|
    opts.banner = "Usage: cd_source [options]"

    # --list/-l
    opts.on("-l", "--list", "List all history") do |v|
      options[:list] = v
    end

    # --get/-g REPO
    opts.on("-g REPO" "--get REPO", "Get repo") do |v|
      options[:get] = v
    end

    # --put/-p REPO DIR
    opts.on("-p REPO DIR", "--put REPO DIR", "Set repo/dir") do |v|
      options[:put] = v
    end

    # --delete/-d
    opts.on("--d KEY", "--delete KEY", "Delete repo") do |v|
      options[:delete] = v
    end

    opts.on("-h", "--help", "Show the help message") do
      puts opts
      exit
    end
  end
  option_parser.parse!
  # puts options.inspect

  if options[:list]
    cd_source = CDSource.new CACHE_FILE, SOURCE_DIRS, nil, MAX_LEVEL
    cd_source.list()
  elsif options[:get]
    repo = options[:get]
    cd_source = CDSource.new CACHE_FILE, SOURCE_DIRS, repo, MAX_LEVEL
    cd_source.search(repo)
  elsif options[:set]
    repo = options[:set]
    dir = ARGV[0]
    cd_source = CDSource.new CACHE_FILE, SOURCE_DIRS, nil, MAX_LEVEL
    cd_source.put(repo, dir)
  elsif options[:delete]
    repo = options[:delete]
    cd_source = CDSource.new CACHE_FILE, SOURCE_DIRS, nil, MAX_LEVEL
    cd_source.delete(repo)
  else
    # print help message
    # puts option_parser.help
    repo = ARGV[0]
    cd_source = CDSource.new CACHE_FILE, SOURCE_DIRS, repo, MAX_LEVEL
    cd_source.search(repo)
  end
end

trap(:INT) { puts "Exit ..."; exit(1); }

if $0 == __FILE__
  main
end
