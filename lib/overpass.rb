require 'open-uri'

require 'rgeo'
require 'rgeo-geojson'
require 'json'

require 'join_ways'

class Overpass
  # TODO move to settings or env variables
  OVERPASS_HOST = 'overpass-api.de'

  class << self
    def extract_relation_polygon(outer_geometries, inner_geometries = [])
      outer_rings = join_ways(outer_geometries)
      inner_rings = join_ways(inner_geometries)

      outer_rings.map do |outer_ring|
        factory.polygon(outer_ring, inner_rings).buffer(0)
      end
    end

    def join_ways(ways)
      JoinWays.to_closed(ways).map do |way|
        factory.line_string(
          way.map do |(lon, lat)|
            factory.point(lon, lat)
          end
        )
      end
    end

    def ways_to_points(ways)
      ways.map do |way|
        [way['lon'], way['lat']]
      end
    end

    def to_relation(members)
      outer_ways = []
      inner_ways = []

      members.each do |member|
        if member['type'] == 'way'
          if member['role'] == 'inner'
            inner_ways << ways_to_points(member['geometry'])
          elsif member['role'] == 'outer' || member['role'].empty?
            outer_ways << ways_to_points(member['geometry'])
          else
            raise "Wrong way role = #{member['role']}"
          end
        end
      end

      extract_relation_polygon(outer_ways, inner_ways).inject(:+)
    end

    def get_geojson(lat, lng)
      url = "http://#{OVERPASS_HOST}/api/interpreter?data=#{URI.escape("[out:json];is_in(#{lat},#{lng});rel(pivot);out geom;")}"

      result = open(url).read
      data = JSON.parse(result)

      RGeo::GeoJSON.encode(to_features(data)).to_json
    end

    def to_features(data)
      features = data['elements'].
        select { |relation| relation['tags']['name'] && ['administrative'].include?(relation['tags']['boundary']) }.
        select { |relation| relation['tags']['historic'] != 'yes' }.
        map { |relation| to_feature(relation) }.
        group_by { |feature| feature.properties['admin_level'].to_i }.
        flat_map { |admin_level, features| admin_level.zero? ? features : features.sort_by { |feature| feature['id'].to_i }.first }.
        sort_by { |v| 0 - v.properties['area'] }

      RGeo::GeoJSON::FeatureCollection.new(features)
    end

    def to_feature(relation)
      id = "#{relation['type']}-#{relation['id']}"
      geometry = cache_fetch id do
        to_relation(relation['members'])
      end

      properties = relation['tags'].clone
      bounding_box = RGeo::Cartesian::BoundingBox.create_from_geometry(geometry)
      properties.merge!(
        'translations' => translations(relation['tags']),
        'area' => geometry.area,
        'bounding_box' => {
          min_x: bounding_box.min_x,
          max_x: bounding_box.max_x,
          min_y: bounding_box.min_y,
          max_y: bounding_box.max_y,
        }
      )

      RGeo::GeoJSON::Feature.new(geometry, id, properties)
    end

    def cache_fetch(id)
      if [nil, 'development'].include?(ENV['RACK_ENV'])
        yield
      else
        filename = "cache/#{id}"
        if File.exists?(filename)
          data = nil
          File.open(filename, 'r') do |f|
            data = Marshal.load(f.read)
          end
          data
        else
          data = yield
          File.open(filename, 'w') do |f|
            f.write(Marshal.dump(data))
          end
          data
        end
      end
    end

    def to_geojson(features)
      features.each do |v|
        File.open("geojsons/#{v.feature_id}", 'w') do |f|
          f.write(RGeo::GeoJSON.encode(v))
        end
      end
    end

    def translations(tags)
      list = tags.map do |key, value|
        _, locale = key.match(/\Aname:(.+)/).to_a
        if locale
          [locale, value]
        end
      end.compact
      hash = list.to_h
      unless hash['en']
        hash['en'] = tags['name']
      end
      hash
    end

    def factory
      @factory ||= RGeo::Geos.factory(native_interface: :capi)
    end
  end
end
