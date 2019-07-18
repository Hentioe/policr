require "kemal"
require "kemal-session"

module Policr::Web
  extend self

  def start(logger, bot)
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

    get "/demo" do
      title = "演示"
      render "src/views/demo.html.ecr", "src/views/layout.html.ecr"
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
      if token = env.params.body["token"]?
        if ((user_id = nil) && KVStore.managed_groups(user_id)) || token == bot.token
          remember = env.params.body["remember"]?
          env.session.string("token", token) unless remember
          if remember
            token_c = HTTP::Cookie.new(
              name: "token",
              value: token,
              http_only: true,
              secure: true,
              expires: Time.new + Time::Span.new(24*30, 0, 0)
            )
            env.response.cookies << token_c
          end
          env.redirect "/admin"
        else
          title = "登录失败，无效的令牌"
          error_msg = "Invalid token"
          render "src/views/login.html.ecr", "src/views/layout.html.ecr"
        end
      else
        title = "登录失败，请提供令牌"
        error_msg = "Missing token"
        render "src/views/login.html.ecr", "src/views/layout.html.ecr"
      end
    end

    get "/admin" do |env|
      if token = find_token(env)
        if (user_id = nil) && (groups = KVStore.managed_groups(user_id))
          title = "后台管理"
          render "src/views/admin.html.ecr", "src/views/layout.html.ecr"
        else
          if token == bot.token
            title = "超级管理后台"
            render "src/views/superadmin.html.ecr"
          else
            env.redirect "/login"
          end
        end
      else
        env.redirect "/login"
      end
    end

    get "/version" do
      VERSION
    end

    get "/serving" do
      groups = Cache.serving_groups
      groups.each_with_index do |group, i|
        _, data = group
        link, name = data
        i += 1
        logger.info "Serving group[#{i}][#{name}]: #{link}"
      end
      "done!+#{groups.size}"
    end

    error 404 do
      "瞎访问啥呢你……"
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
