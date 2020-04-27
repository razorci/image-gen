require 'rake'

require_relative "./src/generator"

def require_lang!(args)
  unless args.lang
    puts "Missing required argument: language"
    exit(1)
  end
end

namespace :generate do
  task :dockerfile, [:lang] do |t, args|
    require_lang!(args)
    GeneratorDocker.run(args.lang)
  end

  task :build, [:lang] do |t, args|
    require_lang!(args)
    BuildDocker.run(args.lang)
  end
end
