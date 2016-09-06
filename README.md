# GEO Pointer

Reverse geocoder of hierarchical OpenStreetMap administrative locations using overpass API.

API service allows to receive hierarchical information of the admin boundaries around the world using the [OSM](http://www.openstreetmap.com/) data through the [overpass API](http://wiki.openstreetmap.org/wiki/Overpass_API).

# How to use

Pass coordinates to the URL `/{lat},{lng}` and receive back GeoJSON features with the locaitons in hierarchical order (from country to the city) with translations, bounding box, meta information, full multipolygon shape geometry and area size.

# Demo

You can try out demo, but please don't use it in production as it could be changed in the nearest future:
[geo.dmitry.eu](http://geo.dmitry.eu/)

# Installation

## Requirements

- ruby 2.2.4
- apt-get install libgeos-dev (GEOS library for rGeo gem)

## Up and run

Use `rackup` in development or `puma`, `passenger` or other `rack` supported server to run in the production.

# TODO

- Allow to setup own overpass API (through the docker-compose) and change setting in the code to use this server
- Add docker file for fast deployment (with puma http server)
- Change everything to use only `rgeo` gem
- Optimize speed and refactor code
- Add more tests of different locations
