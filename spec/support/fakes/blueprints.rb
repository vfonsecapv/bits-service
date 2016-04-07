require 'securerandom'
require 'sham'

Sham.define do
  email               { |index| "email-#{index}@somedomain.com" }
  name                { |index| "name-#{index}" }
  label               { |index| "label-#{index}" }
  token               { |index| "token-#{index}" }
  auth_username       { |index| "auth_username-#{index}" }
  auth_password       { |index| "auth_password-#{index}" }
  provider            { |index| "provider-#{index}" }
  url                 { |index| "https://foo.com/url-#{index}" }
  type                { |index| "type-#{index}" }
  description         { |index| "desc-#{index}" }
  long_description    { |index| "long description-#{index} over 255 characters #{'-' * 255}" }
  version             { |index| "version-#{index}" }
  service_credentials { |index| { "creds-key-#{index}" => "creds-val-#{index}" } }
  binding_options     { |index| { "binding-options-#{index}" => "value-#{index}" } }
  uaa_id              { |index| "uaa-id-#{index}" }
  domain              { |index| "domain-#{index}.example.com" }
  host                { |index| "host-#{index}" }
  guid                { |_| "guid-#{SecureRandom.uuid}" }
  extra               { |index| "extra-#{index}" }
  instance_index      { |index| index }
  unique_id           { |index| "unique-id-#{index}" }
  status              { |_| %w(active suspended cancelled).sample(1).first }
  error_message       { |index| "error-message-#{index}" }
end
