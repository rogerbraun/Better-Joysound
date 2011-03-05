require "rubygems"
require "sinatra"
require "erb"
require "./dump_joysound.rb"


get "/" do
  @results = Joysound.search_by_title(params[:title]) if params[:title]
  erb :index
end

