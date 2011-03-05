#encoding: utf-8
require "nokogiri"
require "open-uri"
require "dm-core"
require "dm-migrations"
require "cgi"



DataMapper.setup(:default, ENV['DATABASE_URL'] | "sqlite:test.db")


class Song
  include DataMapper::Resource

  property :id,   Serial
  property :title, String
  property :artist, String
  property :number, String, :unique => true
  property :genre, String
  property :utaidashi, String

end

DataMapper.auto_upgrade!
  

class Joysound

  def self.search_by_title(title)
    songs_from_artist_page("http://joysound.com/ex/search/songsearch.htm?keyWord=#{CGI::escape(title)}")
  end

  def self.data_from_page(url)
    STDERR.puts "Trying #{url}..."
    parsed = Nokogiri::HTML(open(url))
    title, artist = parsed.css("#musicNameBlock h3").text.strip.split("／")
    number = parsed.css(".wiiTable td:nth-child(2)").text.strip[/\d+/]
    genre = parsed.css(".musicDetailsBlock tr:nth-child(2) a").text.strip
    utaidashi = parsed.css(".musicDetailsBlock tr:nth-child(3) td").text.strip
    
    res = {:title => title, :artist => artist, :number => number, :genre => genre, :utaidashi => utaidashi}
    begin
      Song.create(res)
    rescue => e
      STDERR.puts "Could not create #{res}: #{e}"
    end

    STDERR.puts "got #{res}"
    res
  end

  def self.songs_from_artist_page(url)
    parsed = Nokogiri::HTML(open(url))
    links = parsed.css(".wii a")
    STDERR.puts "Reading links..."
    res = links.map do |link| 
      self.data_from_page("http://joysound.com" + link.attribute("href"))
    end
    if parsed.text["次の20件"] then 
      link = parsed.css(".transitionLinks03 li:last-of-type a")
      STDERR.puts "Found more, reading #{link.attribute('href')}"
      res += self.songs_from_artist_page("http://joysound.com" + link.attribute("href"))
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
