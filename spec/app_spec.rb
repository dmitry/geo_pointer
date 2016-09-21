require 'spec_helper'

require 'rack/test'
require './app'

describe 'hierarchy of' do
  include Rack::Test::Methods

  def app
    App.new
  end

  it '/' do
    get '/'
    expect(last_response).to be_ok
    expect(last_response.body).to start_with('<p>Choose one of the following ')
  end

  it '/53,10' do
    VCR.use_cassette 'hierarchy_of/puerto_de_la_cruz' do
      get '/28.41,-16.54'
    end
    expect(last_response).to be_ok
    expect(JSON.load(last_response.body)['features'].size).to eq(4)
  end
end