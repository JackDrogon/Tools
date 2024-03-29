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
# TODO: Add purge

require 'pstore'
require 'fileutils'
require 'optparse'

CACHE_FILE = "#{ENV['HOME']}/.cs_cache"
SOURCE_DIRS = ["#{ENV['HOME']}/Source", "#{ENV['HOME']}/Source/GitHub"]
MAX_LEVEL = 6

IGNORE_FILEEXTENSIONS = [".c", ".cc", ".cpp", ".h", ".hpp"]

module Helper
  def trip_home(v)
    v.sub ENV["HOME"], "~"
  end

  def real_path(v)
    v.sub "~", ENV["HOME"]
  end

  def git?(dir)
    git_dir = "#{dir}/.git"
    # origin git repo dir or git work tree
    Dir.exist?(git_dir) or File.exist?(git_dir)
  end

  def cs_source?(dir)
    File.exist? "#{dir}/.cs_source"
  end

  def is_7z?(file)
    File.exist?(file) && ! File.directory?(file)
  end
end

class Cache
  include Helper

  def initialize(cache_file)
    @store = PStore.new(cache_file)
  end

  def get(key)
    value = nil
    @store.transaction(true) do
      value = @store.fetch(key, nil)
    end
    value
  end

  def exist(key)
    @store.transaction(true) do
      @store.root? key
    end
  end

  def put(key, value)
    @store.transaction do
      @store[key] = trip_home(value)
    end
  end

  def delete(key)
    @store.transaction do
      @store.delete(key)
    end
  end

  def list
    result = []
    @store.transaction(true) do
      @store.roots.each do |k|
        result << [k, @store[k]]
      end
    end
    result
  end
end

class CDSource
  DirOrFile = Struct.new(:name, :depth)

  include Helper

  def initialize(cache_file, search_dirs, max_level)
    @max_level = max_level
    @search_dirs = (Array === search_dirs) ? search_dirs : [search_dirs]
    @cache = Cache.new(cache_file)
  end

  def put(key, value)
    @cache.put(key, value)
  end

  def delete(key)
    @cache.delete(key)
  end

  def list
    @cache.list
  end

  def get(repo)
    dir = _search_cache(repo)
    if dir.nil?
      _search_dir(repo)
    else
      dir
    end
  end

  private
  # Search repo in cache file
  # if not exist, return false
  # if exist, search real path
  # if real path not exist, delete cache and return false
  # if real path exist, return true
  def _search_cache(repo)
    unless @cache.exist(repo)
      return nil
    end

    rpath = real_path(@cache.get(repo))
    if Dir.exist?(rpath) or File.exist?(rpath)
      rpath
    else
      delete(repo)
      nil
    end
  end

  def _search_dir(repo)
    @search_dirs.each do |sdir|
      dirs = [DirOrFile.new(sdir, 1)]

      # BFS search dir and file
      # Rules
      # 1. depth > max_level skip
      # 2. file/dir
      # dir:
      #  name == repo return
      #  if not git, add all sub dir
      # file: if 7z, skip
      while !dirs.empty?
        dir_or_file = dirs.shift
        next if dir_or_file.depth > @max_level

        name = dir_or_file.name.split("/").last
        path = dir_or_file.name

        # dir_or_file is dir
        if File.directory? path
          if name == repo
            @cache.put(repo, path)
            return path
          end

          unless git?(path) or cs_source?(path)
            # not recursive search in git dir or marked cs_source
            # if not git, add all sub dir
            Dir["#{path}/*"].each do |dir|
              dirs << DirOrFile.new(dir, dir_or_file.depth+1)
            end
          end
          next
        end

        # dir_or_file is file
        # if name == src_7z || name == src
        if name =~ /^#{repo}((\.|(-[0-9]+)).*)?$/
          # puts src, "name", /^#{src}((\.|-?).*)?$/
          unless IGNORE_FILEEXTENSIONS.include? $1 # 应该主动识别是不是压缩文件
            @cache.put(repo, path)
            return path
          end
        end
      end
    end

    nil
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

  cd_source = CDSource.new(CACHE_FILE, SOURCE_DIRS, MAX_LEVEL)
  # create get closure
  get = lambda do |repo|
    dir = cd_source.get(repo)
    if dir.nil?
      puts "Not found repo: #{repo}"
      exit 1
    else
      puts dir
    end
  end
  if options[:list]
    cd_source.list.each do |k, v|
      puts "#{k} => #{v}"
    end
  elsif options[:get]
    repo = options[:get]
    get.call(repo)
  elsif options[:put]
    repo = options[:put]
    dir = ARGV[0]
    cd_source.put(repo, dir)
  elsif options[:delete]
    repo = options[:delete]
    cd_source.delete(repo)
  else
    # print help message
    # puts option_parser.help
    repo = ARGV[0]
    get.call(repo)
  end
end

trap(:INT) { puts "Exit ..."; exit(1); }

if $0 == __FILE__
  main
end
