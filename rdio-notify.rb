#!/usr/bin/env ruby

require 'rubygems'
require 'sinatra'
require 'uri'
require 'yaml'

require_relative 'rdio'
require_relative 'rdio-credentials'

enable :sessions

class Artist
  attr_accessor :name, :key

  def self.from_json(artist)
    new_artist = Artist.new
    new_artist.name = artist['name']
    new_artist.key  = artist['artistKey']

    return new_artist
  end
end


class Album
  attr_accessor :artist, :name, :icon, :short_url

  def self.from_json(album)
    new_album = Album.new
    new_album.name      = album['name']
    new_album.short_url = album['shortUrl']
    new_album.icon      = album['icon']

    new_album.artist      = Artist.new
    new_album.artist.name = album['artist']
    new_album.artist.key  = album['artistKey']

    return new_album
  end
end


def find_new_albums(new_releases, collection_artists)
  new_albums = []

  collection_artists.each do |search_artist|
    new_releases.each do |release|
      if release.artist.key == search_artist.key
        new_albums.push(release)
      end
    end
  end

  return new_albums
end


get '/' do
  access_token = session[:at]
  access_token_secret = session[:ats]
  if access_token and access_token_secret
    rdio = Rdio.new([RDIO_CONSUMER_KEY, RDIO_CONSUMER_SECRET], 
                    [access_token, access_token_secret])

    current_user = rdio.call('currentUser')['result']
    new_releases = rdio.call('getNewReleases', {'time' => 'thisweek'})['result'].collect { |r| Album.from_json(r) }
    new_releases += rdio.call('getNewReleases', {'time' => 'lastweek'})['result'].collect { |r| Album.from_json(r) }
    new_releases += rdio.call('getNewReleases', {'time' => 'twoweeks'})['result'].collect { |r| Album.from_json(r) }
    artists      = rdio.call('getArtistsInCollection')['result'].collect { |a| Artist.from_json(a) }

    new_albums = find_new_albums(new_releases, artists)

    response = "
    <html><head><title>rdio-notify</title></head><body>
    <p>New releases from artists in %s's collection:</p>
    <ul>
    " % current_user['firstName']
    if new_albums
      new_albums.each do |album|
        response += '<li><a href="%s"><img src="%s">%s - %s</a></li>' % [album.short_url, album.icon, album.artist.name, album.name]
      end
    else
      response += "No new releases."
    end
    response += '</ul><a href="/logout">Log out of Rdio</a></body></html>'
    return response
  else
    return '
    <html><head><title>Rdio-Simple Example</title></head><body>
    <a href="/login">Log into Rdio</a>
    </body></html>
    '
  end
end

get '/login' do
  session.clear
  # begin the authentication process
  rdio = Rdio.new([RDIO_CONSUMER_KEY, RDIO_CONSUMER_SECRET])
  callback_url = (URI.join request.url, '/callback').to_s
  url = rdio.begin_authentication(callback_url)
  # save our request token in the session
  session[:rt] = rdio.token[0]
  session[:rts] = rdio.token[1]
  # go to Rdio to authenticate the app
  redirect url
end

get '/callback' do
  # get the state from cookies and the query string
  request_token = session[:rt]
  request_token_secret = session[:rts]
  verifier = params[:oauth_verifier]
  # make sure we have everything we need
  if request_token and request_token_secret and verifier
    # exchange the verifier and request token for an access token
    rdio = Rdio.new([RDIO_CONSUMER_KEY, RDIO_CONSUMER_SECRET], 
                    [request_token, request_token_secret])
    rdio.complete_authentication(verifier)
    # save the access token in cookies (and discard the request token)
    session[:at] = rdio.token[0]
    session[:ats] = rdio.token[1]
    session.delete(:rt)
    session.delete(:rts)
    # go to the home page
    redirect to('/')
  else
    # we're missing something important
    redirect to('/logout')
  end
end

get '/logout' do
  session.clear
  redirect to('/')
end
