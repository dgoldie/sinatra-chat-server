require 'rubygems'
require 'em-websocket'
require 'sinatra/base'
require 'erb'
require 'thin'

EventMachine.run do
  class App < Sinatra::Base
      get '/' do
          erb :chat
      end
  end

  @channel = EM::Channel.new
  @users = {}

  EventMachine::WebSocket.start(:host => '0.0.0.0', :port => 8080) do |ws|
      ws.onopen {
        @users[ws.id] = ws.id
          @channel.push "#{@users[ws.id]} connected."
          ws.send "Type `/nick USERNAME` to change your username."
          @channel.subscribe { |msg| ws.send msg }
      }

      ws.onmessage { |msg|
        if msg[0,1] == "/"
          regex = %r{\/nick (.+)}.match(msg)
          if regex && regex[1]
            @channel.push @users[ws.id].to_s + " is now known as: "+regex[1]
            @users[ws.id] = regex[1]
          end
        else
          @channel.push @users[ws.id].to_s + ": " + msg
        end

      }

      ws.onclose   {
          ws.send "WebSocket closed"
          @channel.unsubscribe(ws)
      }

  end

  App.run!({:port => 3000})
end