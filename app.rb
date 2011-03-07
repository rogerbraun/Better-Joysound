require "rubygems"
require "sinatra"
require "erb"
require "./dump_joysound.rb"


get "/" do
  if params[:title] then
    
    @results = Keyword.all(:keyword.like => "#{params[:title]}%").map(&:songs).flatten.uniq
    puts  "results"

    if not @results.empty? then
      @ongoing = SearchProgress.first(:keyword => params[:title], :finished => false)
    else
      if params[:ongoing]
        @ongoing = !SearchProgress.first(:keyword => params[:title], :finished => true)
      else
        Thread.new {
          Joysound.search_by_title(params[:title], true, 5)
        }
        @ongoing = true  
      end
    end
      
  end
  erb :index
end

