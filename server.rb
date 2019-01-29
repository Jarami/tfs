require 'gserver'
require 'net/http'
require 'tfs.rb'

class TFSServer < GServer

  def initialize(port=10002, *args)
    super(port, *args)
  end

  def serve(io)
    io.set_encoding("UTF-8")

    request = io.gets
    
    puts "request = #{request.inspect}"
    meth, request_text, params, version = parse(request)
    # puts io.to_outputstream.methods.sort-Object.methods
    puts request_text
    if request_text.empty?
      File.open("index.html","r:utf-8"){|f| io.puts f.read }
      
    elsif request_text == "get-files"
      io.puts TFS.get_files(params["version"])
      
    elsif request_text == "label-files"
      io.puts TFS.label_files(params["version"])
      
    else 
      io.puts "Unknown command"
    end

  rescue Exception => err 
    puts err    
    io.puts err.message
  end
  
  def parse request
    
    meth, uri_text, version = request.split(" ")
    puts request

    uri = URI(uri_text)

    request_text = uri.path[1..-1]
    params = uri.query ? Hash[uri.query.split("&").map{|chunk| chunk.split("=") }] : {}
    
    [meth, request_text, params, version]
  end
end

# Run the server with logging enabled (it's a separate thread).
server = TFSServer.new
server.audit = true                  # Turn logging on.
server.start

# *** Now point your browser to http://localhost:10001 to see it working ***

# See if it's still running.
# GServer.in_service?(10001)           # -> true
# server.stopped?                      # -> false

# Shut the server down gracefully.
# server.shutdown

# Alternatively, stop it immediately.
# GServer.stop(10001)
# or, of course, "server.stop".

$stdin.readline()

server.shutdown