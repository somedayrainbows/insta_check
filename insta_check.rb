require 'net/http'
require 'uri'
require 'json'
require 'open3'

def applescript(script)
  Open3.capture3 "osascript", *["-l", "AppleScript", :stdin_data => script]
end

# script will not work unless you customize the three following values:
cookie = "put_your_cookie_here" # log in and go to the network tab -> store -> headers -> cookie, select everything before first semi-colon and _uetsid
retailer = "costco" # or other retailer available in your area
reseller = "put the very specific reseller name here" # you know what to put here

uri = URI.parse("https://www.#{reseller}.com/v3/containers/#{retailer}/next_gen/retailer_information/content/delivery?source=web")
request = Net::HTTP::Get.new(uri)
request.content_type = "application/json"
request["Accept"] = "application/json"
request["Cookie"] = cookie

req_options = {
  use_ssl: uri.scheme == "https",
}

loop do
  response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
    res = http.request(request)
    if res.body.include?("502 Bad Gateway")
      p "502 Bad Gateway with a #{res.code}; trying again."
    else
      parsed = JSON.parse(res.body)
      p res.code
      if res.code == "200"
        err_message = parsed["container"]["modules"][0]["id"]
        # for parsing the message if necessary later: .split("_").reverse.drop(1).reverse.join("_")
        # osascript -e (`tell application \"System Events\" to display dialog \"Hello World\"`)
        # `tell app "Finder" to display dialog "#{err_message}"`
        if !err_message.include?("errors_no_availability")
          p applescript <<-END
            say "#{retailer} SLOT MIGHT BE AVAILABLE!"
            display dialog "#{retailer} appears to have a delivery opening"
          END
        end

        p err_message, Time.now
        sleep 10
      else
        p res.code
        p "Your #{reseller} request failed with a #{res.code}; trying again."
      end
    end
  end
end
