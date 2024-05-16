require 'socket'
require 'openssl'
require 'tk'

require_relative 'url_utils'

WIDTH, HEIGHT = 800, 600

class Browser
    def initialize
        @window = TkRoot.new
        @canvas = TkCanvas.new(width: WIDTH, height: HEIGHT)
        @canvas.pack
    end

    def load(url)
        x1, y1, x2, y2 = 100, 100, 300, 200
        # Draw the rectangle on the canvas
        TkcRectangle.new(@canvas, x1, y1, x2, y2, outline: 'black', fill: 'blue')
        text = TkText.new(@window) do
            width 30
            height 0
            border 1
            font TkFont.new('times 12 bold')
            pack("side" => "left",  "padx"=> "5", "pady"=> "5")
        end
        text.insert 'end', "Hellow"
    end

end








url = URL.new("https://browser.engineering/examples/example1-simple.html")
content = url.request


browser = Browser.new
browser.load(url)
Tk.mainloop


# TO DO:
# - working on redirects rn
#