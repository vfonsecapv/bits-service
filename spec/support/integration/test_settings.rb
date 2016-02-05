module IntegrationTestSettings
  def self.included(base)
    WebMock.allow_net_connect!
  end
end

