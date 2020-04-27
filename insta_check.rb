require 'net/http'
require 'uri'
require 'json'
require 'open3'

def applescript(script)
  Open3.capture3 "osascript", *["-l", "AppleScript", :stdin_data => script]
end

uri = URI.parse("https://www.instacart.com/v3/containers/costco/next_gen/retailer_information/content/delivery?source=web")
request = Net::HTTP::Get.new(uri)
request.content_type = "application/json"
request["Accept"] = "application/json"
request["Cookie"] = "_instacart_session=NzR1S1Z0Um5PbE9mYURGUmJvbDRCTGtPS1VoK294ZjA2U0tpOW9BRFJ5anNtQzdIcUFoM09UcVFHTnpSMHhWZ2RUcE1xM3VzWmV0eHJsU3dVZFJQRDBjMCs1eUtFVkNEQzJvc3NUVzIrTDRJb3duU25QUit2RGhWaHMxSjRjaDVmaUdlUUNJYUkxNGJQRlAwUkY2aTZ6ZTlZdEIvQmJWKzloaFl2Vm5kSUxGcituV1dTNGUvMXRqcEpQR1U2K2MvNnU5U0ZSTFpocUdSN2ExL2hQWkVtZm1zcURoSi8wcThnR0xiVC9mTTEwcXlZRGwvQW93a1BtR2NBZzVJaDMyZzIzb2hoUkZaOTlWZEgzRkh6VEVxaFBPREVSbW1nQ2tLdDJxbjl5bitrcmpuT09XNlVZT2dOUmc4eVBSMkpzT0JMbVpKSTJnQTEzVjkyN1IxcXlPb1lXL0xNV2MwUzRhS2tpVEhJamdQTitRPS0tRjNSUTFqZjFuZkdGc2hiSDVmclU1UT09--a28c1f677cee89bd283639e9807ec577783a5195; ahoy_visit=f1864a20-2609-40ae-a14a-f3d8911d09b5; build_sha=e0dd5996fbe717148822352540172824cd054c03; ajs_anonymous_id=%22e58b090c-5c47-4e3e-8410-6a6152699b1b%22; amplitude_id_b87e0e586f364c2c189272540d489b01instacart.com=eyJkZXZpY2VJZCI6IjA1NzEzYzI1LWRiN2EtNGRhNC1iMzQyLTZjYzRhNWE0ZGE4NFIiLCJ1c2VySWQiOiIzNTMxMDY5NiIsIm9wdE91dCI6ZmFsc2UsInNlc3Npb25JZCI6MTU4NjM1OTM3MjIzMywibGFzdEV2ZW50VGltZSI6MTU4NjM1OTYxNzE2MCwiZXZlbnRJZCI6ODQsImlkZW50aWZ5SWQiOjcsInNlcXVlbmNlTnVtYmVyIjo5MX0=; __stripe_mid=5eadae69-0df2-45b4-a3ac-ecdd2fa747a3; __stripe_sid=0ef97393-b36f-433c-be47-d18068c217a1; __ssid=ba1d075deaf51c439799f90d9be7436; ab.storage.sessionId.6f8d91cb-99e4-4ad7-ae83-652c2a2c845d=%7B%22g%22%3A%228ae80661-8941-8fc4-efe2-06aeb2831095%22%2C%22e%22%3A1586361216037%2C%22c%22%3A1586359412203%2C%22l%22%3A1586359416037%7D; ajs_user_id=%2235310696%22; forterToken=d3bb781aa14945ea83b84d27a3484612_1586359414483__UDF43_9ck; ftr_ncd=6; ajs_group_id=null; amplitude_idundefinedinstacart.com=eyJvcHRPdXQiOmZhbHNlLCJzZXNzaW9uSWQiOm51bGwsImxhc3RFdmVudFRpbWUiOm51bGwsImV2ZW50SWQiOjAsImlkZW50aWZ5SWQiOjAsInNlcXVlbmNlTnVtYmVyIjowfQ==; _instacart_logged_in=1; ab.storage.deviceId.6f8d91cb-99e4-4ad7-ae83-652c2a2c845d=%7B%22g%22%3A%2213845b40-8bd1-43c1-4609-e5ddd35c71d2%22%2C%22c22%3A1586359412204%2C%22l%22%3A1586359412204%7D; ab.storage.userId.6f8d91cb-99e4-4ad7-ae83-652c2a2c845d=%7B%22g%22%3A%2235310696%22%2C%22c%22%3A1586359412202%2C%22l%22%3A1586359412202%7D; _fbp=fb.1.1586359372745.1387188922; _gcl_au=1.1.1840605278.1586359372; ahoy_visitor=9db0c201-0d91-44e2-86fc-27c58defd632"

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
            say "COSTCO SLOT MIGHT BE AVAILABLE!"
            display dialog "Costco appears to have an opening"
          END
        end

        p err_message, Time.now
        sleep 10
      else
        p res.code
        p "Instacart request failed with a #{res.code}; trying again."
      end
    end
  end
end
