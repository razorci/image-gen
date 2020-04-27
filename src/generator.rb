require "fileutils"

require_relative "util"
require_relative "section"

class Generator
  attr_accessor :language
  attr_accessor :output_dir

  def initialize(lang, outdir)
    self.language = lang
    self.output_dir = outdir

    @layers = []
    @variants = []
    @sections = []
    @user_sections = []
    @base = nil

    @tag_filter = @tag_include_filter = []
  end

  def run()
    exitWith("No :base set for #{self.language}") unless @base

    puts "Generating manifest for #{self.language}:"
    FileUtils.rmdir(File.join(self.output_dir, self.language)) rescue nil
  
    find_tags_and_aliases(@base, @tag_filter, @tag_include_filter).each do |aliases|
      out = StringIO.new
      tag = aliases.shift

      write_header(out)
      out.puts

      write_base(out, @base, tag)
      out.puts

      write_install_standard(out)
      out.puts

      @sections.each do |sec|
        write_section(out, sec)
      end

      write_ci_user(out)
      out.puts

      @user_sections.each do |sec|
        write_section(out, sec)
      end

      @layers.each do |layer|
        key, info = layer
        out.puts %Q{## #{key}} if key
        out.puts(info)
        out.puts
      end

      write_cmd(out)
      out.flush

      path = File.join(self.output_dir, self.language, tag)
      FileUtils.mkdir_p(path)

      puts "\t #{tag}, #{aliases}"

      image_base = "#{DOCKER_REPO}/#{self.language}"

      write_file(File.join(path, "Dockerfile"), out)
      write_file(File.join(path, "TAG"), tag)
      write_file(File.join(path, "IMAGE"), image_base)
      write_file(File.join(path, "ALIASES"), aliases.join(",")) if aliases

      @variants.each do |variant|
        case variant
        when "node", :node
          node_manifest_gen(tag)
        else
          puts "Unsuported language variant: #{variant}"
        end
      end
    end
  end

  def manifest_gen(tag)
    out = StringIO.new
    write_header(out)
    out.puts

    write_base(out, @base, tag)
    out.puts

    write_install_standard(out)
    @sections.each do |sec|
      out.puts
      write_section(out, sec)
    end

    out.puts
    write_ci_user(out)
    
    @layers.each do |key, info|
      out.puts
      out.put(%Q{## #{key}})
      out.puts(info)
    end

    write_cmd(out)
    out.flush

    path = File.join(self.output_dir, self.language, tag)
    FileUtils.mkdir_p(path)

    puts "\t #{tag}, #{aliases}"

    image_base = "#{DOCKER_REPO}/#{lang}"

    write_file(File.join(path, "Dockerfile"), out)
    write_file(File.join(path, "TAG"), tag)
    write_file(File.join(path, "IMAGE"), image_base)
    write_file(File.join(path, "ALIASES"), aliases.join(",")) if aliases
  end

  def node_manifest_gen(tag)
    out = StringIO.new
    base_repo = "#{DOCKER_REPO}/#{self.language}"
    variant_tag = "#{tag}-node"

    write_header(out)
    out.puts

    write_base(out, base_repo, variant_tag)
    out.puts

    write_official_nodejs(out)
    out.flush

    path = File.join(self.output_dir, self.language, tag, "node")
    FileUtils.mkdir_p(path)
    write_file(File.join(path, "Dockerfile"), out)
  end

  private

  def base(tag)
    @base = tag
  end

  def layers(*secs)
    @sections |= secs
  end

  def user_layers(*secs)
    @user_sections |= secs
  end

  def variants(*vars)
    @variants |= vars
  end

  def layer(message, input=nil)
    if input == nil
      message = nil 
      input = message
    end

    @layers << [message, input]
  end

  def tag_filter(*values)
    @tag_filter |= build_regex(*values)
  end

  def tag_include_filter(*values)
    @tag_include_filter |= build_regex(*values)
  end
end

module GeneratorDocker
  def self.run(lang)
    path = "languages/#{lang}"
    outdir = ENV.fetch("DIRECTORY") { "dist" }

    gen = Generator.new(lang, outdir)
    File.open(path) { |f| gen.instance_eval(f.read) }
    gen.run
  end
end

module BuildDocker
  def self.run(lang)
    outdir = File.join(ENV.fetch("DIRECTORY") { "dist" }, lang)
    do_push = ENV["DOCKER_PUSH"] != ""

    Dir.children(outdir).each do |tag|
      path = File.join(outdir, tag)

      Dir.chdir(path) do
        aliases = File.read("ALIASES").split(",").map(&:strip) rescue []
        image = File.read("IMAGE").strip
        docker_image = "#{image}:#{tag}"
        puts "Building #{docker_image}"

        docker_exec("docker build -t #{docker_image} .")

        aliase_images = []
        if aliases.size > 0
          aliase_images = aliases.map { |t| "#{image}:#{t}" }
          docker_exec("docker tag #{docker_image} #{aliase_images.join(" ")}")
        end

        docker_exec("docker push #{docker_image} #{aliase_images.join(" ")}") if do_push

        Dir.children(".").each do |variant|
          puts
          variant_image = "#{image}:#{tag}-#{variant}"
          docker_exec("docker build -t #{variant_image} #{variant}")
          docker_exec("docker push #{variant_image}") if do_push
        end

        puts
      end
    end
  end
end
