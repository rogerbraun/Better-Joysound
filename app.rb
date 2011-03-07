require "rubygems"
require "sinatra"
require "erb"
require "./dump_joysound.rb"


get "/" do
  if params[:title] then
    @results = Keyword.all(:keyword.like => "#{params[:title]}%").map(&:songs).flatten.uniq
    unless SearchProgress.first(:keyword => params[:title], :finished => false) or params[:ongoing]
      Thread.new {
        Joysound.search_by_title(params[:title], true, 5)
      }
      @ongoing = true  
    else
      
      @ongoing = SearchProgress.first(:keyword => params[:title], :finished => false)
    end
      
  end
  erb :index
end

