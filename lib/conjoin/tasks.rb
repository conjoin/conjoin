dir = Gem::Specification.find_by_name('cuba-tracks').gem_dir

Dir.glob("#{dir}/lib/cuba/tasks/**/*.rb").each { |r| require r  }
Dir.glob("#{dir}/lib/cuba/tasks/**/*.rake").each { |r| import r  }
