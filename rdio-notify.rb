#!/usr/bin/env ruby

require 'rubygems'
require 'sinatra'
require 'uri'

require './vendor/ruby/rdio'
require './rdio_consumer_credentials'

enable :sessions

get '/' do
  access_token = session[:at]
  access_token_secret = session[:ats]
  if access_token and access_token_secret
    rdio = Rdio.new([RDIO_CONSUMER_KEY, RDIO_CONSUMER_SECRET], 
                    [access_token, access_token_secret])

    currentUser = rdio.call('currentUser')['result']
    playlists = rdio.call('getPlaylists')['result']['owned']

    response = "
    <html><head><title>Rdio-Simple Example</title></head><body>
    <p>%s's playlists:</p>
    <ul>
    " % currentUser['firstName']
    playlists.each do |playlist|
      response += '<li><a href="%s">%s</a></li>' % [playlist['shortUrl'], playlist['name']]
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
