# https://gist.github.com/rmw/2710460
require 'hashie'

class Hash
  # options:
  #   :exclude => [keys] - keys need to be symbols
  def to_ostruct(options = {})
    convert_to_ostruct_recursive(self, options)
  end

  def with_sym_keys
    # self.inject({}) { |memo, (k,v)| memo[k.to_sym] = v; memo  }
    self.each_with_object({}) { |(k,v), memo| memo[k.to_sym] = v }
  end

  private

  def convert_to_ostruct_recursive(obj, options)
    result = obj
    if result.is_a? Hash
      result = result.dup.with_sym_keys
      result.each  do |key, val|
        result[key] = convert_to_ostruct_recursive(val, options) unless options[:exclude].try(:include?, key)
      end
      result = OpenStruct.new result
    elsif result.is_a? Array
      result = result.map { |r| convert_to_ostruct_recursive(r, options) }
    end
    return result
  end
end

class HashIndifferent < Hash
  include Hashie::Extensions::MergeInitializer
  include Hashie::Extensions::IndifferentAccess
end

class OpenStruct
  def to_hash options = {}
    convert_to_hash_recursive(self, options)
  end

  private

  def convert_to_hash_recursive(obj, options)
    result = obj
    if result.is_a? OpenStruct
      result = result.dup.to_h.with_sym_keys
      result.each do |key, val|
        result[key] = convert_to_hash_recursive(val, options) unless options[:exclude].try(:include?, key)
      end
      result = HashIndifferent.new result
    elsif result.is_a? Array
      result = result.map { |r| convert_to_hash_recursive(r, options) }
    end
    return result
  end
end

# require 'spec_helper'
#
# describe Hash do
#
#   describe "#to_ostruct_recursive" do
#     describe "replace a nested hash" do
#       before do
#         @h = { :a => { :b => { :c => 1 } } }
#         @o = @h.to_ostruct_recursive
#       end
#       it "should be an OpenStruct" do
#         @o.is_a?(OpenStruct).should be_true
#       end
#       it "should have a nested OpenStruct" do
#         @o.a.should be
#         @o.a.is_a?(OpenStruct).should be_true
#       end
#       it "should have a nested nested OpenStruct" do
#         @o.a.b.should be
#         @o.a.b.is_a?(OpenStruct).should be_true
#       end
#       it "should have a nested nested nested value of 1" do
#         @o.a.b.c.should be
#         @o.a.b.c.should == 1
#       end
#       describe "exclude a key from being converted to an OpenStruct" do
#         before do
#           @o_exclude = @h.to_ostruct_recursive({ :exclude => [:b] })
#         end
#         it "should be an OpenStruct" do
#           @o.is_a?(OpenStruct).should be_true
#         end
#         it "should have a nested OpenStruct" do
#           @o.a.is_a?(OpenStruct).should be_true
#         end
#         it "should have a nested nested Hash" do
#           @o_exclude.a.b.is_a?(Hash).should be_true
#           @o_exclude.a.b.should == { :c => 1 }
#         end
#       end
#     end
#     describe "replace a nest hash in an array" do
#       before do
#         @h = { :a => [ {:a1 => 1 } ] }
#         @o = @h.to_ostruct_recursive
#       end
#       it "should be an OpenStruct" do
#         @o.is_a?(OpenStruct).should be_true
#       end
#       it "should have an array with 1 struct" do
#         @o.a.is_a?(Array).should be_true
#         @o.a.size.should == 1
#         @o.a.first.is_a?(OpenStruct).should be_true
#         @o.a.first.a1.should == 1
#       end
#     end
#   end
# end
