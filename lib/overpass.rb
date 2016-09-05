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
require 'geo_ruby/geojson'

require 'endpoint_converter'

class Overpass
  # TODO move to settings or env variables
  OVERPASS_HOST = 'overpass-api.de'

  class << self
    def extract_relation_polygon(outer_geometries, inner_geometries = [])
      outer_rings = join_ways(outer_geometries)
      inner_rings = join_ways(inner_geometries)

      outer_rings.map do |outer_ring|
        GeoRuby::SimpleFeatures::Polygon.from_linear_rings([outer_ring] + inner_rings)
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
          if member['role'] == "inner"
            inner_ways << way_geometry(member['geometry'])
          elsif member['role'] == "outer" || member['role'].blank?
            outer_ways << way_geometry(member['geometry'])
          else
            raise "Wrong way role = #{member['role']}"
          end
        end
      end

      boundary_polygons = extract_relation_polygon(outer_ways, inner_ways)

      if boundary_polygons.present?
        GeoRuby::SimpleFeatures::MultiPolygon.from_polygons(boundary_polygons)
      end
    end

    def get_geojson(lat, lng)
      url = "http://#{OVERPASS_HOST}/api/interpreter?data=#{URI.escape("[out:json];is_in(#{lat},#{lng});rel(pivot);out geom;")}"

      result = open(url).read
      data = JSON.parse(result)

      to_geojson(data).to_json
    end

    def to_geojson(data)
      features = data['elements'].map do |relation|
        id = "#{relation['type']}-#{relation['id']}"
        geometry = to_relation(relation['members'])
        tags = {name: relation['tags']['name']}
        feature = GeoRuby::GeoJSONFeature.new(geometry, tags, id)
        feature
      end
      GeoRuby::GeoJSONFeatureCollection.new(features).to_json
    end
  end
end
