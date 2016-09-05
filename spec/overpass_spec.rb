require 'spec_helper'

require 'overpass'

describe 'Rspec filtering' do
  it 'gets hierarchy of hamburg', :vcr => true do

    response = Overpass.get_geojson(53.5642280, 9.9830910)

    p response.size
  end
end