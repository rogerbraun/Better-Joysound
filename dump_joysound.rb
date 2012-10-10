#encoding: utf-8
require "nokogiri"
require "open-uri"
require "dm-core"
require "dm-migrations"
require "cgi"
require "thread"


class Song
  include DataMapper::Resource

  property :id,   Serial
  property :title, String, :length => 256
  property :artist, String, :length => 256
  property :number, String, :unique => true
  property :genre, String, :length => 256
  property :utaidashi, String, :length => 256

  has n, :keywords, :through => Resource

end

class Keyword
  include DataMapper::Resource

  property :id, Serial
  property :keyword, String
  property :kind, String

  has n, :songs, :through => Resource
end
  
class SearchProgress
  include DataMapper::Resource

  property :id, Serial
  property :keyword, String
  property :finished, Boolean
  
end

  

class Joysound

  def self.search_by_title(title, threaded = false, n = 4)
    s = SearchProgress.first_or_create(:keyword => title)
    s.finished = false
    s.save

    begin
    load_song_links_from_artist_page("http://joysound.com/ex/search/songsearchword.htm?wiiall=1&searchType=01&searchWord=#{CGI::escape(title)}&searchWordType=2&searchLikeType=2", "title", threaded, n, title)
    #load_song_links_from_artist_page("http://joysound.com/ex/search/songsearch.htm?keyWord=#{CGI::escape(title)}","title",  threaded, n, title)
    rescue => e
      STDERR.puts e
    end

    s.finished = true
    s.save
  end

  def self.search_by_artist(query, threaded = false, n = 4)
    s = SearchProgress.first_or_create(:keyword => query)
    s.finished = false
    s.save

    begin
      load_artists_from_letter_page("http://joysound.com/ex/search/artistsearchword.htm?wiiall=1&searchType=01&searchWord=#{CGI::escape(query)}&searchWordType=1&searchLikeType=2", "artist", threaded, n, query)
      #load_artists_from_letter_page("http://joysound.com/ex/search/artistsearch.htm?keyWord=#{CGI::escape(query)}", "artist", threaded, n, query)
    rescue => e
      STDERR.puts e
    end

    s.finished = true
    s.save
  end

  def self.load_links(links, kind, keyword)
    links = links.map{|link| link.attribute("href")}
    links.each do |link|
       res = self.data_from_page("http://joysound.com/" + link)
       self.save_to_db(res, keyword)
    end
  end

  def self.load_links_threaded(links, kind, keyword, n = 4)
    links = links.map{|link| link.attribute("href")}

    semaphore = Mutex.new
    
    links.each_slice(n) do |slice|
      threads = slice.map do |link|
        Thread.new(link, semaphore){ |url, semaphore| 
          res = self.data_from_page("http://joysound.com/" + url) 
          semaphore.synchronize {
            self.save_to_db(res,keyword, kind)
            sleep 0.5
          }    
        }
      end
      threads.map(&:join)
    end
  end

  def self.save_to_db(res, keyword, kind)
    song = Song.first_or_create(res)
    puts song
    kw = Keyword.first_or_create(:keyword => keyword, :kind => kind)
    puts kw
    kw.songs << song
    kw.save
  end
    

  def self.data_from_page(url)
   # STDERR.puts "Trying #{url}..."
    parsed = nil
    while(!parsed) do
      begin 
        parsed = Nokogiri::HTML(open(url))
      rescue OpenURI::HTTPError
        STDERR.puts "Waiting for #{url}..."
        sleep 0.5
      end
    end
    title, artist = parsed.css("#musicNameBlock h3").text.strip.split("／")
    number = parsed.css(".wiiTable td:nth-child(2)").text.strip[/\d+/]
    genre = parsed.css(".musicDetailsBlock tr:nth-child(2) a").text.strip
    utaidashi = parsed.css(".musicDetailsBlock tr:nth-child(3) td").text.strip
    
    res = {:title => title, :artist => artist, :number => number, :genre => genre, :utaidashi => utaidashi}

    #STDERR.puts "got #{res}"
    res
  end

  def self.load_song_links_from_artist_page(url, kind, threaded, n, title)
    STDERR.puts "Reading links..."
    parsed = nil
    while(!parsed) do
      begin 
        parsed = Nokogiri::HTML(open(url))
      rescue OpenURI::HTTPError
        STDERR.puts "Waiting for #{url}..."
        sleep 0.5
      end
    end
    links = parsed.css(".wii a")
      threaded ? self.load_links_threaded(links, kind,  title, n) : self.load_links(links, kind, title)
    if parsed.text["次の20件"] then 
      link = parsed.css(".transitionLinks03 li:last-of-type a")
      STDERR.puts "Found more, reading #{link.attribute('href')}"
      self.load_song_links_from_artist_page("http://joysound.com" + link.attribute("href"),kind, threaded, n, title)
    end
    links
  end

  def self.load_artists_from_letter_page(url, kind, threaded, n, query)

    parsed = nil
    while(!parsed) do
      begin 
        parsed = Nokogiri::HTML(open(url))
      rescue OpenURI::HTTPError
        STDERR.puts "Waiting for #{url}..."
        sleep 0.5
      end
    end
    links = parsed.css(".wii a")
    STDERR.puts "Reading links..."
    res = links.map do |link| 
      self.load_song_links_from_artist_page("http://joysound.com" + link.attribute("href"), kind, threaded, n, query)
    end
      
    if parsed.text["次の20件"] then 
      link = parsed.css(".transitionLinks03 li:last-of-type a")
      STDERR.puts "Found more, reading #{link.attribute('href')}"
      self.load_artists_from_letter_page("http://joysound.com" + link.attribute("href"), kind, threaded, n, query)
    end

    res

  end
  def self.artists_from_letter_page(url)

    parsed = Nokogiri::HTML(open(url))
    links = parsed.css(".wii a")
    STDERR.puts "Reading links..."
    res = links.map do |link| 
      self.songs_from_artist_page("http://joysound.com" + link.attribute("href"))
    end
      
    if parsed.text["次の20件"] then 
      link = parsed.css(".transitionLinks03 li:last-of-type a")
      STDERR.puts "Found more, reading #{link.attribute('href')}"
      res += self.artists_from_letter_page("http://joysound.com" + link.attribute("href"))
    end

    res

  end


  def self.artists_from_letter_page(url)

    parsed = Nokogiri::HTML(open(url))
    links = parsed.css(".wii a")
    STDERR.puts "Reading links..."
    res = links.map do |link| 
      self.songs_from_artist_page("http://joysound.com" + link.attribute("href"))
    end
      
    if parsed.text["次の20件"] then 
      link = parsed.css(".transitionLinks03 li:last-of-type a")
      STDERR.puts "Found more, reading #{link.attribute('href')}"
      res += self.artists_from_letter_page("http://joysound.com" + link.attribute("href"))
    end

    res

  end
    
end

