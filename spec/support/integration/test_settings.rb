module IntegrationTestSettings
  def self.included(_base)
    WebMock.allow_net_connect!
  end
end
