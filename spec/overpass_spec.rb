require 'spec_helper'

require 'overpass'

describe 'hierarchy of' do
  it 'hamburg', :vcr => true do
    response = Overpass.get_geojson(53.5642280, 9.9830910)
    json = JSON.parse(response)
    expect('FeatureCollection').to eq json['type']
    expect(5).to eq json['features'].size
    expect(252).to eq json['features'].first['properties']['translations'].size
  end

  it 'puerto de la cruz', :vcr => true do
    response = Overpass.get_geojson(28.41, -16.54)
    json = JSON.parse(response)
    expect('FeatureCollection').to eq json['type']
    expect(4).to eq json['features'].size
  end

  it 'dublin', :vcr => true do
    response = Overpass.get_geojson(53.397187, -6.426769)
    json = JSON.parse(response)
    expect('FeatureCollection').to eq json['type']
    expect(6).to eq json['features'].size
  end

  it 'seychelles', :vcr => true do
    response = Overpass.get_geojson(-4.6261077, 55.446254)
    json = JSON.parse(response)
    expect('FeatureCollection').to eq json['type']
    expect(2).to eq json['features'].size
  end
end