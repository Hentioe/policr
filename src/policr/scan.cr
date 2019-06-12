module Policr
  class Image
    def initialize(@files : Array(String), @name_zh_hans : String)
    end

    def name(lang = :zh_hans)
      @name_zh_hans
    end

    def random_file
      i = Random.rand(0...@files.size)
      @files[i]
    end
  end

  IGNORES = [".", ".."]

  def self.scan(path)
    root = "#{path}/captcha#images"
    dir = Dir.new root
    dirs = dir.select { |f| !IGNORES.includes?(f) && File.directory?("#{root}/#{f}") }.map { |f| "#{root}/#{f}" }
    gen_cache dirs
  end

  def self.gen_cache(dirs)
    images = dirs.map do |path|
      rawdata = File.read "#{path}/metadata.json"
      metadata = JSON.parse rawdata
      name_zh_hans = metadata.as_h["name_zh_hans"].as_s
      dir = Dir.new path
      files = dir.select { |f| !IGNORES.includes?(f) && !File.directory?("#{path}/#{f}") }.map { |f| "#{path}/#{f}" }
      scaned_files = files.select { |f| /^\d*\./ =~ File.basename(f) }
      Image.new scaned_files, name_zh_hans
    end

    Cache.set_images images
  end
end
