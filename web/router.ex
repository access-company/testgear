# Copyright(c) 2015-2024 ACCESS CO., LTD. All rights reserved.

defmodule Testgear.Router do
  use Antikythera.Router

  static_prefix "/custom/static/path"

  websocket "/ws"

  get  "/"                        , Hello, :html
  get  "/html"                    , Hello, :html, as: "html"
  get  "/var_bindings"            , Hello, :var_bindings
  get  "/html_escaping"           , Hello, :html_escaping
  get  "/partial"                 , Hello, :partial
  get  "/dot.and~tilde_in_route"  , Hello, :html
  get  "/foo/:hoge/:bar/*wildcard", Hello, :json, as: "routing_test"
  get  "/json"                    , Hello, :json
  post "/json"                    , Hello, :json
  get  "/json_via_g2g"            , Hello, :json_via_g2g
  get  "/redirect"                , Hello, :redirect
  post "/body_parser"             , Hello, :body_parser
  get  "/path_matches/:a/:b/:c/*d", Hello, :path_matches
  get  "/camelized_header_key"    , Hello, :camelized_header_key
  get  "/gzip_compressed"         , Hello, :gzip_compressed
  post "/gzip_compressed"         , Hello, :gzip_compressed_post
  get  "/incorrect_content_length", Hello, :incorrect_content_length
  get  "/override_default_header" , Hello, :override_default_header
  get  "/xml"                     , Hello, :xml
  get  "/sse_short"               , Hello, :sse_short, streaming: true
  get  "/sse_long"                , Hello, :sse_long, streaming: true
  get  "/auth_greeting"           , Hello, :auth_greeting

  get  "/priv_file/*file", StaticAsset, :send_priv_file
  get  "/asset_urls"     , StaticAsset, :urls

  get "/config_cache", ConfigCache, :check

  get  "/report_log"        , Reporting, :log
  get  "/report_metric"     , Reporting, :metric
  post "/register_async_job", Reporting, :register_async_job

  post "/action1_with_plug"            , ActionWithPlug, :action1
  post "/action2_with_plug"            , ActionWithPlug, :action2
  get  "/action_plug_error"            , ActionWithPlug, :action_plug_error
  get  "/action_plug_before_send_error", ActionWithPlug, :action_plug_before_send_error

  get "/basic_authentication_with_config", BasicAuthentication, :check_with_config
  get "/basic_authentication_with_fun"   , BasicAuthentication, :check_with_fun

  get    "/cookie"          , Cookie, :show
  post   "/cookie"          , Cookie, :create
  delete "/cookie"          , Cookie, :destroy
  get    "/multiple_cookies", Cookie, :multiple_cookies

  get    "/session", Session, :show
  post   "/session", Session, :create
  delete "/session", Session, :destroy
  get    "/session_with_set_cookie_option", Session, :with_set_cookie_option

  get "/flash"            , Flash, :show
  get "/flash/with_notice", Flash, :with_notice
  get "/flash/redirect"   , Flash, :redirect

  post "/content_decoding", ContentDecoding, :echo, as: "content_decoding"

  get   "/only_from_web"             , Hello, :json, from: :web
  only_from_web do
    get "/using_only_from_web_block" , Hello, :json
  end
  get   "/only_from_gear"            , Hello, :json, from: :gear
  only_from_gear do
    get "/using_only_from_gear_block", Hello, :json
  end

  post "/params_validation/:foo", ParamsValidation, :validate_params
  post "/list_body_validation"  , ParamsValidation, :validate_list_body
  post "/map_body_validation"   , ParamsValidation, :validate_map_body

  get "/exception"           , Error, :action_exception
  get "/throw"               , Error, :action_throw
  get "/exit"                , Error, :action_exit
  get "/timeout"             , Error, :action_timeout
  get "/timeout_long"        , Error, :action_timeout, timeout: 12_000
  get "/incorrect_return"    , Error, :incorrect_return
  get "/json_with_status"    , Error, :json_with_status
  get "/missing_status_code" , Error, :missing_status_code
  get "/illegal_resp_body"   , Error, :illegal_resp_body
  get "/exhaust_heap_memory" , Error, :exhaust_heap_memory
  get "/bad_executor_pool_id", Error, :just_to_add_route_but_never_be_executed

  post   "/openapi/:mypath/one" , OpenApi, :one_post
  get    "/openapi/:mypath/one" , OpenApi, :one_get
  put    "/openapi/:mypath/one" , OpenApi, :one_put
  delete "/openapi/:mypath/one" , OpenApi, :one_delete
  get    "/openapi/two"         , OpenApi, :two
  get    "/openapi/json"        , OpenApi, :json
  get    "/openapi/query"       , OpenApi, :query
  get    "/openapi/header"      , OpenApi, :header
  get    "/openapi/cookie"      , OpenApi, :cookie
  post   "/openapi/req_body"    , OpenApi, :req_body
  post   "/openapi/req_body_ref", OpenApi, :req_body_ref
  get    "/openapi/all_of"      , OpenApi, :all_of

  post   "/mcp", Mcp, :chunked_response, streaming: true
  get    "/mcp", Mcp, :method_not_allowed
  delete "/mcp", Mcp, :method_not_allowed

  get "/stress/pi/:loop"  , Stress, :pi
  get "/stress/list/:loop", Stress, :list
end
