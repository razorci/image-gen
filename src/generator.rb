require "fileutils"
require "json"

require_relative "util"
require_relative "section"
require_relative "erbalt"

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

  def write_readme(lang_desc)
    exit_with("No :base set for #{self.language}") unless @base
    puts "Generating README.md for #{self.language}:"
    path = File.join(self.output_dir, self.language, "README.md")
    template_path = File.read("src/README.dockerhub.md")

    File.open(path, "w") do |f|
      rnd = ErbalT.new({ lang_code: self.language, language: lang_desc })
      f.write(rnd.render(template_path))
    end
  end

  def run
    exit_with("No :base set for #{self.language}") unless @base

    puts "Generating manifest for #{self.language}:"
    FileUtils.rm_rf(File.join(self.output_dir, self.language))

    image_base = "#{DOCKER_REPO}/#{self.language}"
    manifest = { base: image_base, items: [] }

    find_tags_and_aliases(@base, @tag_filter, @tag_include_filter).each do |aliases|
      out, tag = StringIO.new, aliases.shift

      puts "Found tags: #{tag} #{aliases}"

      section_tag = tag
      if language == "openjdk"
        matches = tag.match(/^(\d+)-/)
        if matches
          section_tag = matches[1]
        end
      end

      manifest_item, variant_mf = {
        tag: tag,
        aliases: aliases,
      }, []

      write_header(out)
      out.puts

      write_base(out, @base, tag)
      out.puts

      write_install_standard(out)
      out.puts

      @sections.each do |sec|
        write_section(out, sec, language, section_tag)
      end

      write_ci_user(out)
      out.puts

      @user_sections.each do |sec|
        write_section(out, sec, language, section_tag)
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

      write_file(File.join(path, "Dockerfile"), out)
      write_file(File.join(path, "TAG"), tag)
      write_file(File.join(path, "IMAGE"), image_base)
      write_file(File.join(path, "ALIASES"), aliases.join(",")) if aliases

      @variants.each do |variant|
        case variant
        when "node", :node
          variant_mf << variant
          node_manifest_gen(tag)
        else
          puts "Unsuported language variant: #{variant}"
        end
      end

      manifest_item[:variants] = variant_mf
      manifest[:items] << manifest_item
    end

    manifest_path = File.join(self.output_dir, self.language, "manifest.json")
    File.open(manifest_path, "w") { |f| f.puts(JSON.pretty_generate(manifest)) }
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
    from_tag = "#{tag}"

    write_header(out)
    out.puts

    write_base(out, base_repo, from_tag)
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

  def layer(message, input = nil)
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
  def self.run(lang, outdir)
    path = "languages/#{lang}"
    gen = Generator.new(lang, outdir)
    File.open(path) { |f| gen.instance_eval(f.read) }
    gen.run
  end
end

module BuildDocker
  def self.run(lang, outdir)
    allowed_tags = ENV.fetch("TAGS", "").split(",").map(&:strip)
    allowed_variants = ENV.fetch("VARIANTS", "").split(",").map(&:strip)

    do_push = !!ENV["DOCKER_PUSH"]
    language_path = File.join(outdir, lang)

    Dir.children(language_path).each do |tag|
      path = File.join(language_path, tag)
      if allowed_tags.size > 0
        next unless allowed_tags.include?(tag)
      end

      next unless File.directory?(path)

      Dir.chdir(path) do
        aliases = File.read("ALIASES").split(",").map(&:strip) rescue []
        image = File.read("IMAGE").strip
        docker_image = "#{image}:#{tag}"
        puts "Building #{docker_image}"

        docker_exec("docker build -t #{docker_image} .")
        docker_exec("docker push #{docker_image}") if do_push

        aliases.each do |t|
          target_image = "#{image}:#{t}"
          docker_exec("docker tag #{docker_image} #{target_image}")
          docker_exec("docker push #{target_image}") if do_push
        end

        Dir.children(".").each do |variant|
          if File.directory?(variant)
            if allowed_variants.size > 0
              next unless allowed_variants.include?(variant)
            end

            puts "\n\t==> generating variant #{variant}"
            variant_image = "#{image}:#{tag}-#{variant}"
            docker_exec("docker build -f #{variant}/Dockerfile -t #{variant_image} #{variant}")
            docker_exec("docker push #{variant_image}") if do_push
          end
        end

        puts
      end
    end
  end
end
