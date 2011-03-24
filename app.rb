require "rubygems"
require "sinatra"
require "erb"
require "./dump_joysound.rb"


get "/" do
  if params[:query] then
    params[:query].downcase!
    
    @results = Keyword.all(:keyword.like => params[:query], :kind.like => params[:kind]).map(&:songs).flatten.uniq
    puts  "results"

    if not @results.empty? then
      @ongoing = SearchProgress.first(:keyword => params[:query], :finished => false)
    else
      if params[:ongoing]
        @ongoing = !SearchProgress.first(:keyword => params[:query], :finished => true)
      else
        Thread.new {
          Joysound.search_by_title(params[:query],  true) if params[:kind] == "title"
          Joysound.search_by_artist(params[:query],  true) if params[:kind] == "artist"
        }
        @ongoing = true  
      end
    end
      
  end

  if request.cookies["songs"]
    puts request.cookies["songs"]
    @remembered = Song.all(:number => request.cookies["songs"].split(",")) 
  end
  erb :index
end

get "/running" do
  SearchProgress.first(:keyword => params[:query], :finished => false) ? "true" : "false"
end


get "/search" do
  @ongoing = SearchProgress.first(:keyword => params[:query], :finished => false)
  @results = Keyword.all(:keyword.like => params[:query], :kind.like => params[:kind]).map(&:songs).flatten.uniq
  erb :results
end

post "/song/:id/remember" do
  songs = request.cookies["songs"] || ""
  songs = songs.split(",").push(params[:id]).uniq.join(",") 
  puts songs
  response.set_cookie "songs", :value => songs, :domain => "", :path => "/"
  redirect back
end

post "/song/:id/forget" do
  songs = request.cookies["songs"] || ""
  songs = songs.split(",").reject{|el| el == (params[:id])}.uniq.join(",") 
  puts songs
  response.set_cookie "songs", :value => songs, :domain => "", :path => "/"
  redirect back
end

get "/song/txt" do
  attachment("joysound.txt")
  @remembered = Song.all(:number => request.cookies["songs"].split(",")) 
  @remembered.map{|song| "#{song.artist} - #{song.title}: #{song.number}"}.join("\n")
end
