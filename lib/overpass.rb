require 'open-uri'

require 'georuby'
require 'active_support/all'
require 'georuby-ext/georuby/point'
require 'georuby-ext/georuby/line_string'
require 'georuby-ext/georuby/multi_polygon'
require 'georuby-ext/georuby/polygon'
require 'georuby-ext/georuby/geometry'
require 'georuby-ext/georuby/srid'
require 'georuby-ext/rgeo/feature/rgeo'
require 'georuby-ext/rgeo/feature/geometry'
require 'georuby-ext/rgeo/feature/geometry_collection'
require 'rgeo'
require 'rgeo-geojson'

require 'endpoint_converter'

class GeoRuby::SimpleFeatures::Srid
  def rgeo_factory
    @rgeo_factory ||= RGeo::Geos.factory(:native_interface => :capi)
  end
end


class Overpass
  # TODO move to settings or env variables
  OVERPASS_HOST = 'overpass-api.de'

  class << self
    def extract_relation_polygon(outer_geometries, inner_geometries = [])
      outer_rings = join_ways(outer_geometries)
      inner_rings = join_ways(inner_geometries)

      outer_rings.map do |outer_ring|
        GeoRuby::SimpleFeatures::Polygon.from_linear_rings([outer_ring] + inner_rings).to_rgeo.buffer(0)
      end
    end

    def join_ways(ways)
      EndpointConverter.new(ways).closed_ways
    end

    def way_geometry(nodes)
      points = nodes.map do |node|
        GeoRuby::SimpleFeatures::Point.from_x_y(node['lon'], node['lat'], 4326)
      end

      if points.present? &&  1 < points.count
        GeoRuby::SimpleFeatures::LineString.from_points(points, 4326)
      end
    end

    def to_relation(members)
      outer_ways = []
      inner_ways = []

      members.each do |member|
        if member['type'] == 'way'
          if member['role'] == 'inner'
            inner_ways << way_geometry(member['geometry'])
          elsif member['role'] == 'outer' || member['role'].blank?
            outer_ways << way_geometry(member['geometry'])
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