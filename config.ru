$:.unshift File.join(File.dirname(__FILE__), "lib")

ENV['RACK_ENV'] ||= 'development'

require 'rubygems'
require 'bundler'

Bundler.require :default, ENV['RACK_ENV'].to_sym

require './app'
run App