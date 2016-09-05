require 'vcr'
require 'rspec'

$:.unshift File.join(File.dirname(__FILE__), "../lib")

RSpec.configure do |c|
  c.extend VCR::RSpec::Macros
end

VCR.configure do |c|
  c.hook_into :webmock
  c.cassette_library_dir = 'spec/cassettes'
  c.configure_rspec_metadata!
end