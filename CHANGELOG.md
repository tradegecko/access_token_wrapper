## 0.2.1 (2018-01-23)
- [BUGFIX] Allow the request to fallback to the old style if no expires_at provided

## 0.2.0 (2018-01-16)
- [FEATURE] The library now checks the expires_at date of the token before attempting an API call.
- [BREAKING] The refresh callback now only optionally contains an exception, when an exception is raised, if the refresh is due to the expires_at field (which should be the majority of the time) it will be `nil`

## 0.1.0 (2017-09-20)
- [BREAKING] `AccessTokenWrapper::Base#token` was renamed to `#raw_token`.