# To learn more about this algorithm look to the:
# https://github.com/mapaslivres/estados/blob/665c72ff034b63c81104eb911c7d492e5c4d2186/lib/osmdb.js
# https://github.com/openstreetmap/iD/blob/604d1e2719d5468095b8721b4d32853f5f18f666/modules/geo/multipolygon.js
class EndpointConverter
  attr_accessor :endpoints, :ways

  def initialize(ways)
    @ways = ways
    @endpoints = {}
  end

  def closed_ways
    closed_ways = []
    ways.each do |way|
      if way.closed?
        closed_ways << way
      else
        # Are there any existing ways we can join this to?
        to_join_to = get_from_either_end(way)
        if to_join_to.present?
          joined = way
          to_join_to.find do |existing_way|
            joined = join_way(joined, existing_way)
            if joined.closed?
              closed_ways << joined
              true
            else
              false
            end
          end

          unless joined.closed?
            add_way(joined)
          end
        else
          add_way(way)
        end
      end
    end

    if number_of_endpoints != 0
      raise StandardError, "Unclosed boundaries"
    end

    closed_ways
  end

  def join_way(way, other)
    if way.closed?
      raise StandardError, "Trying to join a closed way to another"
    end
    if other.closed?
      raise StandardError, "Trying to join a way to a closed way"
    end

    if way.points.first == other.points.first
      new_points = other.reverse.points[0..-2] + way.points
    elsif way.points.first == other.points.last
      new_points = other.points[0..-2] + way.points
    elsif way.points.last == other.points.first
      new_points = way.points[0..-2] + other.points
    elsif way.points.last == other.points.last
      new_points = way.points[0..-2] + other.reverse.points
    else
      raise StandardError, "Trying to join two ways with no end point in common"
    end

    remove_way(other)

    GeoRuby::SimpleFeatures::LineString.from_points(new_points)
  end

  def add_way(way)
    if get_from_either_end(way).present?
      raise StandardError, "Call to add_way would overwrite existing way(s)"
    end
    self.endpoints[way.points.first] = way
    self.endpoints[way.points.last] = way
  end

  def remove_way(way)
    endpoints.delete(way.points.first)
    endpoints.delete(way.points.last)
  end

  def get_from_either_end(way)
    [].tap do |selected_end_points|
      selected_end_points << endpoints[way.points.first] if endpoints.include?(way.points.first)
      selected_end_points << endpoints[way.points.last] if endpoints.include?(way.points.last)
    end
  end

  def number_of_endpoints
    endpoints.size
  end
end
