require "rubygems"
require "sinatra"
require "sinatra/reloader" if development?
require "erb"
require "./dump_joysound.rb"
require "cgi"

class User
  include DataMapper::Resource

  property :id, Serial
  property :email, String
  property :songs, Text
end

DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite:test.db")
DataMapper.auto_upgrade!

helpers do
  def logged_in?
    request.cookies["user"] && (not request.cookies["user"].empty?)
  end

  def current_user
    User.get(request.cookies["user"].to_i)
  end

  def log_in(email)
    response.set_cookie "user", :value => @user.id, :domain => "", :path => "/"
    response.set_cookie "songs", :value => @user.songs, :domain => "", :path => "/"
  end
  
  def set_songs(arr)
    songs = arr.uniq.join(",")
    response.set_cookie "songs", :value => songs, :domatin => "", :path => "/" 
    current_user.update(:songs => songs) if logged_in?
  end

  def get_songs
    if logged_in?
      current_user.songs.split(",")
    else
      request.cookies["songs"] ? request.cookies["songs"].split(",") : []
    end
  end

  def log_out
    response.set_cookie("user", :value => nil, :path => "/", :domain => "")
    response.set_cookie("songs", :value => nil, :path => "/", :domain => "")
  end
end

get "/" do
  if params[:query] then
    params[:query].downcase!
    
    @results = Keyword.all(:keyword.like => params[:query], :kind.like => params[:kind]).map(&:songs).flatten.uniq
    puts  "results"

    if (not @results.empty?) and (not params[:force]) then
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

  if not get_songs.empty?
    @remembered = Song.all(:number => get_songs) 
    @results -= @remembered if @results
  end
  erb :index
end

get "/user" do
  @users = User.all
  erb :users
end

get "/user/new" do
  erb :new_user
end

post "/user/logout" do
  log_out
  redirect to "/"
end

post "/user/new" do
  @user = User.first(:email => params[:email])
  if not @user
    @user = User.create(:email => params[:email], :songs => request.cookies["songs"] || "")
  end
  log_in(params[:email])
  redirect to "/"
end

get "/running" do
  SearchProgress.first(:keyword => params[:query], :finished => false) ? "true" : "false"
end

get "/search/live" do
  SearchProgress.all.map(&:keyword).reverse.join("<br >")
end
  
get "/search" do
  @ongoing = SearchProgress.first(:keyword => params[:query], :finished => false)
  @results = Keyword.all(:keyword.like => params[:query], :kind.like => params[:kind]).map(&:songs).flatten.uniq
  if not get_songs.empty?
    @remembered = Song.all(:number => get_songs)
    @results -= @remembered if @results
  end
  erb :results
end

get "/remembered" do
  if not get_songs.empty?
    @remembered = Song.all(:number => get_songs)
  end
  erb :remembered
end

post "/song/:id/remember" do
  songs = get_songs.push(params[:id])
  set_songs(songs)
  !request.xhr? ? redirect(back) : "Remembered!"
end

post "/song/:id/forget" do
  songs = get_songs
  songs = songs.reject{|el| el == (params[:id])}
  set_songs(songs)
  !request.xhr? ? redirect(back) : "Forgotten!"
end

get "/song/txt" do
  attachment("joysound.txt")
  @remembered = Song.all(:number => request.cookies["songs"].split(",")) 
  @remembered.map{|song| "#{song.artist} - #{song.title}: #{song.number}"}.join("\n")
end
