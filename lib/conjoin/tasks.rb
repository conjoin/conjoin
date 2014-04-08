dir = Gem::Specification.find_by_name('conjoin').gem_dir

Dir.glob("#{dir}/lib/conjoin/tasks/**/*.rb").each { |r| require r  }
Dir.glob("#{dir}/lib/conjoin/tasks/**/*.rake").each { |r| import r  }
