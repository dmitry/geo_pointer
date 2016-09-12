require 'spec_helper'

require 'overpass'

describe 'hierarchy of' do
  it 'hamburg', :vcr => true do
    response = Overpass.get_geojson(53.5642280, 9.9830910)
    expect(response.size).to eq 3480635
    json = JSON.parse(response)
    expect(json['type']).to eq 'FeatureCollection'
    expect(json['features'].size).to eq 5
    expect(json['features'].first['properties']['translations'].size).to eq 252
  end

  it 'puerto de la cruz', :vcr => true do
    response = Overpass.get_geojson(28.41, -16.54)
    json = JSON.parse(response)
    expect('FeatureCollection').to eq json['type']
    expect(json['features'].size).to eq 4
  end

  it 'dublin', :vcr => true do
    response = Overpass.get_geojson(53.397187, -6.426769)
    json = JSON.parse(response)
    expect('FeatureCollection').to eq json['type']
    expect(json['features'].size).to eq 6
  end

  it 'dublin without historic', :vcr => true do
    response = Overpass.get_geojson(53.338893, -6.239656)
    json = JSON.parse(response)
    expect('FeatureCollection').to eq json['type']
    expect(json['features'].map { |v| v['properties']['name'] }).to eq(["Ireland", "Leinster", "County Dublin", "Dublin", "South Dock ED"])
    expect(json['features'].size).to eq 5
  end

  it 'seychelles', :vcr => true do
    response = Overpass.get_geojson(-4.6261077, 55.446254)
    json = JSON.parse(response)
    expect('FeatureCollection').to eq json['type']
    expect(json['features'].size).to eq 2
  end
end