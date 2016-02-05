require 'net/http'
require 'uri'
require 'rest-client'

module IntegrationHttp
  module JsonBody
    def json_body
      @json_body ||= JSON.parse(body)
    end
  end

  def make_get_request(path, headers={}, port=8181)
    url = URI.parse("http://localhost:#{port}#{path}")

    response = Net::HTTP.new(url.host, url.port).start do |http|
      request = Net::HTTP::Get.new(url.request_uri)
      headers.each do |name, value|
        request.add_field(name, value)
      end
      http.request(request)
    end

    response.extend(JsonBody)
    response
  end

  def make_post_request(path, data, headers={}, port=8181)
    http = Net::HTTP.new('localhost', port)
    response = http.post(path, data, headers)
    response.extend(JsonBody)
    response
  end

  def make_put_request(path, data, headers={})
    http = Net::HTTP.new('localhost', '9292')
    response = http.put(path, data, headers)
    response.extend(JsonBody)
    response
  end

  def make_delete_request(path, headers={})
    http = Net::HTTP.new('localhost', '9292')
    response = http.delete(path, headers)
    response.extend(JsonBody)
    response
  end

  def make_options_request(path, headers={})
    http = Net::HTTP.new('localhost', '9292')
    response = http.options(path, headers)
    response.extend(JsonBody)
    response
  end

  def make_multipart_put_request(path, body)
    RestClient.put "http://localhost:9292#{path}", body
  end
end
