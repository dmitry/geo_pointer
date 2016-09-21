require 'sinatra'
require 'overpass'

EXAMPLE_LOCATIONS = {
  'Hamburg' => [53, 10],
  'Dublin' => [53.3, -6.2],
  'Puerto de la Cruz' => [28.41, -16.54],
}

class App < Sinatra::Base
  error do
    content_type :json
    JSON.dump('error' => 'Internal error. Write dmitry.polushkin@gmail.com to get the support.')
  end

  get '/' do
    slim :index, locals: {locations: EXAMPLE_LOCATIONS}
  end

  get '/:lat,:lng' do
    content_type :json
    JSON.dump(Overpass.get_geojson(params[:lat].to_f, params[:lng].to_f))
  end
end
