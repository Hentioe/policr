require "kemal"
require "kemal-session"

module Policr::Web
  extend self

  def start(logger)
    config = CLI::Config.instance
    serve_static({"gzip" => false})
    public_folder "public"
    Kemal.config.logger = LoggerHandler.new(logger)

    Kemal::Session.config do |config|
      config.secret = "demo_sec"
    end

    get "/" do
      title = "专注于审核的 Telegram 机器人"
      render "src/views/index.html.ecr", "src/views/layout.html.ecr"
    end

    get "/guide" do
      title = "使用指南"
      render "src/views/guide.html.ecr", "src/views/layout.html.ecr"
    end

    get "/login" do |env|
      token = find_token env
      if token
        env.redirect "/admin"
      else
        title = "登录后台"
        error_msg = nil
        render "src/views/login.html.ecr", "src/views/layout.html.ecr"
      end
    end

    post "/login" do |env|
      title = "后台管理"
      if (token = env.params.body["token"]?) && (user_id = DB.find_user_by_token(token.strip)) && DB.managed_groups(user_id)
        env.session.string("token", token)
        env.redirect "/admin"
      else
        error_msg = "Login failed"
        render "src/views/login.html.ecr", "src/views/layout.html.ecr"
      end
    end

    get "/admin" do |env|
      if (token = find_token(env)) && (user_id = DB.find_user_by_token(token.strip)) && (groups = DB.managed_groups(user_id))
        title = "后台管理"
        render "src/views/admin.html.ecr", "src/views/layout.html.ecr"
      else
        env.redirect "/login"
      end
    end

    get "/version" do
      VERSION
    end

    error 404 do
      "建设中……"
    end

    Kemal.config.env = "production" if config.prod
    Kemal.run(args: nil, port: config.port)
  end

  def find_token(env)
    token = env.session.string?("token")
    unless token
      if token_c = env.request.cookies["token"]?
        token_c.value
      end
    else
      token
    end
  end
end
