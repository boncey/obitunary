#!/usr/bin/env ruby

require 'rubygems'
require 'wikipedia'
require 'itunes/library'
require 'optparse'

@verbose = false
@debug = false

def main(param)

  if (File.exist?(param))
    puts "iTunes mode" if @verbose
    library_file = param
    puts "Reading artists from #{library_file}"
    library = ITunes::Library.load(library_file)

    artists = artists(library)
    deceased = lookup(artists)
    alive = artists - deceased

    puts "#{artists.size} artists"
    puts "#{deceased.size} deceased"
    puts "#{alive.size} alive"
  else
    puts "Artist mode" if @verbose
    @verbose = true
    artist = lookup_artist(param)
  end
end

def lookup(artists)
  puts "Looking up artists in Wikipedia"
  deceased = []

  artists.each do |artist|
    if (artist.length > 0 && lookup_artist(artist))
      deceased << artist
    end
    sleep 5
  end

  deceased
end

def lookup_artist(artist_name)
  puts "Looking up artist '#{artist_name}'" if @verbose
  page = Wikipedia.find(artist_name)

  puts page.content if @debug
  if (page.content == nil) || (!page.content.include?("Infobox musical artist")) || (page.content.include?("group_or_band"))
    artist = Artist.new(artist_name)
    artist.unrecognised = true
    puts "#{artist_name} is not an artist" if @verbose
  else
    deceased = page.content && page.content.downcase.include?("death date and age")
    artist = Artist.new(artist_name, deceased)

    if (artist.deceased?)
      puts "#{artist_name} is deceased :-("
    elsif (artist.alive?)
      puts "#{artist_name} is still alive :-)"
    end
  end

  artist
end

def artists(library)
  artists = library.music.tracks.map(&:artist)

  artists.uniq
end

opts_parser = OptionParser.new do |opts|
  opts.banner = "Usage: obitunary.rb [options] <iTunes library file|artist>"
  opts.separator "obitunary.rb '~/Music/iTunes/iTunes Music Library.xml' - lookup all artists found in iTunes file"
  opts.separator "obitunary.rb 'Lalo Schifrin' lookup an individual artist"
  opts.separator "Artist mode is assumed if parameter can't be read as a file"
  opts.on("-v", "--verbose", "Be more verbose") do
    @verbose = true
  end
  opts.on("-d", "--debug", "Dump raw data to assist debugging") do
    @debug = true
  end
end
opts_parser.parse!

if (ARGV.empty?)
  puts opts_parser.help
  exit
end

class Artist
  attr_accessor :name, :deceased, :unrecognised

  def initialize(name, deceased = false)
    self.name = name
    self.deceased = deceased
  end

  def alive?
    !self.deceased
  end

  def deceased?
    self.deceased
  end

  def unrecognised?
    self.unrecognised
  end
end

main(ARGV[0])

