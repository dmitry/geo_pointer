require 'sinatra'
require 'overpass'

EXAMPLE_LOCATIONS = {
  'Hamburg' => [53.5642280, 9.9830910]
}

# TODO add logger https://github.com/sinatra/sinatra/blob/master/sinatra-contrib/lib/sinatra/custom_logger.rb

get '/' do
  slim :index, locals: {locations: EXAMPLE_LOCATIONS}
end

get '/:lat,:lng' do
  Overpass.get_geojson(params[:lat].to_f, params[:lng].to_f)
end
