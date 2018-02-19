#!/usr/bin/env ruby

require 'set'
require 'find'
require 'digest'
require 'fileutils'

WORD_PATH = '/Applications/Microsoft Word.app'.freeze
EXCEL_PATH = '/Applications/Microsoft Excel.app'.freeze
ONENOTE_PATH = '/Applications/Microsoft OneNote.app'.freeze
OUTLOOK_PATH = '/Applications/Microsoft Outlook.app'.freeze
POWERPOINT_PATH = '/Applications/Microsoft PowerPoint.app'.freeze
TRASH = "#{ENV['HOME']}/.Trash/Office".freeze

# doc: all files base on PATHS[0] files
PATHS = [WORD_PATH, EXCEL_PATH, ONENOTE_PATH, OUTLOOK_PATH, POWERPOINT_PATH].freeze

def find_all_files_with_no_prefix(dir)
  set = Set.new
  Find.find(dir) do |filename|
    unless File.directory?(filename) || File.symlink?(filename)
      set << filename[dir.length, filename.length] if filename != dir
    end
  end
  set
end

def find_same_files(dir1, dir2)
  set1 = find_all_files_with_no_prefix(dir1)
  set2 = find_all_files_with_no_prefix(dir2)
  set = set1 & set2
  same = set.select do |filename|
    (File.lstat(dir1 + filename).ino != File.lstat(dir2 + filename).ino) \
    && (Digest::MD5.file(dir1 + filename).hexdigest == Digest::MD5.file(dir2 + filename).hexdigest)
  end
  same
end

def backup_file(filename)
  dest_filename = TRASH + filename
  FileUtils.mkdir_p File.dirname(dest_filename)
  puts "Move #{filename} to #{dest_filename}"
  FileUtils.mv filename, dest_filename
end

def trims_all_same_files(dir1, dir2)
  same_files = find_same_files(dir1, dir2)
  same_files.each do |filename|
    backup_file dir2 + filename
    FileUtils.ln dir1 + filename, dir2 + filename
  end
end

if Process.euid != 0
  puts "Need root priviledge, Please run: sudo ruby #{__FILE__}"
  exit 1
end

PATHS[1, PATHS.length].each do |pathname|
  puts "#{PATHS[0]}, #{pathname}"
  trims_all_same_files(PATHS[0], pathname)
end
puts 'Office thinning completed!'
puts "Backup files in #{TRASH}"
