require 'rest-client'

module IntegrationHttp
  def make_multipart_put_request(path, body)
    RestClient.put "http://localhost:9292#{path}", body
  end
end
