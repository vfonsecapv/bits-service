require 'rest-client'

module IntegrationHttp
  def endpoint
    'http://localhost:9292'
  end

  def make_get_request(path)
    RestClient.get "#{endpoint}#{path}"
  rescue Errno::ECONNREFUSED => e
    raise e
  rescue => e
    e.response
  end

  def make_put_request(path, body=nil)
    RestClient.put "#{endpoint}#{path}", body
  rescue Errno::ECONNREFUSED => e
    raise e
  rescue => e
    e.response
  end

  def make_post_request(path, body, headers={})
    RestClient.post "#{endpoint}#{path}", body, headers
  rescue Errno::ECONNREFUSED => e
    raise e
  rescue => e
    e.response
  end

  def make_delete_request(path)
    RestClient.delete "#{endpoint}#{path}"
  rescue Errno::ECONNREFUSED => e
    raise e
  rescue => e
    e.response
  end
end
