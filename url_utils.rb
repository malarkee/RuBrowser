module URLMethods 
    def init_http_helper(url_path, scheme)
        url_path = url_path.sub('//', '')               # remove leftover slashes
        port = {"http" => 80, "https" => 443}[scheme]   # set port for given scheme
        url_path += '/' unless url_path.include?('/')   # add '/' if there isn't one
        host, path = (parts = url_path.split('/', 2); [parts[0], "/#{parts[1]}"])
        return port, host, path
    end
    
    def init_file_helper(url_path)
        url_path = url_path.sub('//', '')   # remove leftover slashes
        unless File.file?(url_path)         # check if file exists, use default if nil
            url_path = "/home/ethanl/code/browser_project/file_scheme_test.txt"
        end
        return url_path
    end
    
    def init_data_helper(url_path)
        #   Could be improved to add support
        #   for base64 and different media types
        media_type, data = url_path.split(',', 2)   
        if media_type.empty?    # check if type exists, use default if nil
            media_type = "text/plain;charset=US-ASCII"
        end
        return media_type, data
    end
    
    def socket_connect(port, host, scheme)
        socket = Socket.new( Socket::AF_INET, Socket::SOCK_STREAM, Socket::IPPROTO_TCP )
        socket.connect( Socket.pack_sockaddr_in( port, host ) )
        if scheme == "https"
            ssl_socket = OpenSSL::SSL::SSLSocket.new( socket, context = OpenSSL::SSL::SSLContext.new )
            ssl_socket.sync_close = true
            ssl_socket.connect
            socket = ssl_socket
        end
        socket
    end
end

class URL
    include URLMethods
    attr_accessor :scheme, :url, :port, :host, :path
    def initialize(url) 
        @socket = nil
        @scheme, url = url.split(":", 2)
        @view_source = false

        # check view-source
        if scheme.include?("view-source")
            @view_source = true
            @scheme, url = url.split(":", 2)
        end

        # http/https URLs
        if scheme == "http" or scheme == "https"
            @port, @host, @path = init_http_helper(url, @scheme)

        # file URLs
        elsif scheme == "file"
            @path = init_file_helper(url)

        # data URI (inline html)
        elsif scheme == "data"
            @media_type, @data = init_data_helper(url)
        end
    end

    def request
        # http/https URLs
        if @scheme == "http" or scheme == "https"
            @socket = socket_connect(@port, @host, @scheme) unless @socket && !@socket.closed?
            # check address port
            if @host.include?(":")
                @host, @port = @host.split(":", 2)
                @port = @port.to_i
            end

            request = "GET #{@path} HTTP/1.0\r\n"
            request += "Host: #{@host}\r\n"
            request += "User-Agent: test_browser\r\n"
            request += "\r\n"

            @socket.write(request.encode("UTF-8"))
            
            status = @socket.gets
            version, status_code, explanation = status.split(" ", 3)

            response_headers = {} # create empty map for response headers

            loop do
                line = @socket.gets
                break if line == "\r\n"

                header, value = line.split(":", 2)
                response_headers[header.downcase] = value.strip!
            end

            # if status_code.to_i >= 300 && status_code.to_i < 400
            #     puts response_headers["location"]
            # end
            
            raise "Transfer header is present" if response_headers.key?("transfer_encoding")
            raise "Content header is present" if response_headers.key?("content_header")

            content = @socket.read(response_headers["content-length"].to_i)
            @socket.close

        # file URLs
        elsif @scheme == "file"
            content = File.read(@path)

        # data URI ( inline html )
        elsif @scheme == "data"
            content = @data
        end
        content
    end

    def show(body)
        unless @view_source or @scheme == "file"
            body = body.gsub(/<[^>]+>|(&lt;)|(&gt;)/) do |match|
                case match
                when /<[^>]+>/ then ''  # remove tags
                when '&lt;' then '<'    # replace &lt; with <
                when '&gt;' then '>'    # replace &gt; with >
                end
            end
        end
        print body
    end

    def load(url)
        body = url.request
        show(body)
    end
end


# to/do
# * compression
# * cache
# * redirects
# * keep-alive