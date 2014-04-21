require 'mab'

def mab(&blk)
  Mab::Builder.new({}, self, &blk).to_s
end
