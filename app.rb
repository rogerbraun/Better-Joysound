require "rubygems"
require "sinatra"
require "erb"
require "./dump_joysound.rb"


get "/" do
  if params[:query] then
    
    @results = Keyword.all(:keyword.like => params[:query]).map(&:songs).flatten.uniq
    puts  "results"

    if not @results.empty? then
      @ongoing = SearchProgress.first(:keyword => params[:query], :finished => false)
    else
      if params[:ongoing]
        @ongoing = !SearchProgress.first(:keyword => params[:query], :finished => true)
      else
        Thread.new {
          Joysound.search_by_title(params[:query], true) if params[:kind] == "title"
          Joysound.search_by_artist(params[:query], true) if params[:kind] == "artist"
        }
        @ongoing = true  
      end
    end
      
  end
  erb :index
end

get "/running" do
  SearchProgress.first(:keyword => params[:query], :finished => false) ? "true" : "false"
end


get "/search" do
  @ongoing = SearchProgress.first(:keyword => params[:query], :finished => false)
  @results = Keyword.all(:keyword.like => params[:query]).map(&:songs).flatten.uniq
  erb :results
end
