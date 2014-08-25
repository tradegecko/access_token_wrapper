# AccessTokenWrapper

Provides a wrapper for an OAuth2::Token to automatically refresh the expiry token when required.

## Installation

Add this line to your application's Gemfile:

    gem 'access_token_wrapper'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install access_token_wrapper

## Usage

```ruby
def access_token
  @access_token ||= begin
    token = OAuth2::AccessToken.new(oauth_client, @user.access_token,
            refresh_token: @user.refresh_token,
            expires_at:    @user.expires_at
    )
    AccessTokenWrapper::Base.new(token) do |new_token, exception|
      update_client_from_access_token(new_token)
    end
  end
end

def oauth_client 
  @oauth_client ||= OAuth2::Client.new(ENV["OAUTH_ID"], ENV["OAUTH_SECRET"], site: "https://api.tradegecko.com")
end

def update_user_from_access_token(new_token)
  @user.access_token  = new_token.token
  @user.refresh_token = new_token.refresh_token
  @user.expires_at    = new_token.expires_at
  @user.save
end
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
