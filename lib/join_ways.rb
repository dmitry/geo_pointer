# To learn more about this algorithm look to the:
# https://github.com/mapaslivres/estados/blob/665c72ff034b63c81104eb911c7d492e5c4d2186/lib/osmdb.js
# https://github.com/openstreetmap/iD/blob/604d1e2719d5468095b8721b4d32853f5f18f666/modules/geo/multipolygon.js
class JoinWays
  attr_accessor :endpoints, :ways, :closed_ways

  def self.to_closed(ways)
    new(ways).closed_ways
  end

  def initialize(ways)
    @ways = ways
    @endpoints = {}
    @closed_ways = []

    process
  end

  private

  def process
    ways.each do |way|
      if closed?(way)
        closed_ways << way
      else
        try_to_join(way)
      end
    end

    if endpoints.size != 0
      p 'Unclosed boundaries'
    end
  end

  def try_to_join(way)
    to_join_to = get_from_either_end(way)
    unless to_join_to.empty?
      joined = way
      to_join_to.find do |existing_way|
        joined = join_way(joined, existing_way)
        if closed?(joined)
          closed_ways << joined
          true
        else
          false
        end
      end

      unless closed?(joined)
        add_way(joined)
      end
    else
      add_way(way)
    end
  end

  def join_way(way, other)
    if closed?(way)
      raise StandardError, 'Trying to join a closed way to another'
    end
    if closed?(other)
      raise StandardError, 'Trying to join a way to a closed way'
    end

    if way.first == other.first
      joined = other.reverse[0..-2] + way
    elsif way.first == other.last
      joined = other[0..-2] + way
    elsif way.last == other.first
      joined = way[0..-2] + other
    elsif way.last == other.last
      joined = way[0..-2] + other.reverse
    else
      raise StandardError, 'Trying to join two ways with no end point in common'
    end

    remove_way(other)

    joined
  end

  def add_way(way)
    unless get_from_either_end(way).empty?
      raise StandardError, 'Call to add_way would overwrite existing way(s)'
    end
    self.endpoints[way.first] = way
    self.endpoints[way.last] = way
  end

  def closed?(way)
    way.first == way.last
  end

  def remove_way(way)
    endpoints.delete(way.first)
    endpoints.delete(way.last)
  end

  def get_from_either_end(way)
    [endpoints[way.first], endpoints[way.last]].compact
  end
end
