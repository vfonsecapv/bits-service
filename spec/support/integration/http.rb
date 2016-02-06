require 'rest-client'

module IntegrationHttp
  def make_put_request(path, body)
    begin
      RestClient.put "http://localhost:9292#{path}", body
    rescue => e
      e.response
    end
  end
end
