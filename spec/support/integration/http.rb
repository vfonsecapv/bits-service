require 'rest-client'

module IntegrationHttp
  def endpoint
    'http://localhost:9292'
  end

  def make_get_request(path)
    begin
      RestClient.get "#{endpoint}#{path}"
    rescue => e
      e.response
    end
  end

  def make_put_request(path, body)
    begin
      RestClient.put "#{endpoint}#{path}", body
    rescue => e
      e.response
    end
  end
end
