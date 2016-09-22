require 'spec_helper'

require 'overpass'

describe 'hierarchy of' do
  it 'hamburg', :vcr => true do
    json = Overpass.get_geojson(53.5642280, 9.9830910)
    expect(JSON.dump(json).size).to eq 3480775
    expect(json['type']).to eq 'FeatureCollection'
    expect(json['features'].size).to eq 5
    expect(json['features'].first['id']).to eq 51477
    expect(json['features'].last['id']).to eq 179545
    expect(json['features'].first['properties']['translations'].size).to eq 252
  end

  it 'puerto de la cruz', :vcr => true do
    json = Overpass.get_geojson(28.41, -16.54)
    expect('FeatureCollection').to eq json['type']
    expect(json['features'].size).to eq 4
  end

  it 'dublin', :vcr => true do
    json = Overpass.get_geojson(53.397187, -6.426769)
    expect('FeatureCollection').to eq json['type']
    expect(json['features'].size).to eq 6
  end

  it 'dublin without historic', :vcr => true do
    json = Overpass.get_geojson(53.338893, -6.239656)
    expect('FeatureCollection').to eq json['type']
    expect(json['features'].map { |v| v['properties']['name'] }).to eq(["Ireland", "Leinster", "County Dublin", "Dublin", "South Dock ED"])
    expect(json['features'].size).to eq 5
  end

  it 'seychelles', :vcr => true do
    json = Overpass.get_geojson(-4.6261077, 55.446254)
    expect('FeatureCollection').to eq json['type']
    expect(json['features'].size).to eq 2
  end

  it 'barcelona', :vcr => true do
    json = Overpass.get_geojson(41.381003,2.146518)
    expect('FeatureCollection').to eq json['type']
    expect(json['features'].size).to eq 7
  end

  it 'florianopolis', :vcr => true do
    json = Overpass.get_geojson(-27.677571,-48.503033)
    expect('FeatureCollection').to eq json['type']
    expect(json['features'].size).to eq 7
  end

  it 'booklyn', :vcr => true do
    json = Overpass.get_geojson(40.683038, -73.926095)
    expect(json['features'].map { |v| v['properties']['name'] }).to eq(["United States of America", "New York", "New York City", "Kings County"])
    expect('FeatureCollection').to eq json['type']
    expect(json['features'].size).to eq 4
  end
end