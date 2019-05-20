require "kemal"

module Policr::Web
  extend self

  def start
    config = CLI::Config.instance
    serve_static({"gzip" => false})
    public_folder "public"

    get "/" do
      title = "专注于审核的 Telegram 机器人"
      render "src/views/index.html.ecr", "src/views/layout.html.ecr"
    end

    get "/guide" do
      title = "使用指南"
      render "src/views/guide.html.ecr", "src/views/layout.html.ecr"
    end

    get "/login" do
      title = "登录后台"
      error_msg = nil
      render "src/views/login.html.ecr", "src/views/layout.html.ecr"
    end

    post "/admin" do |env|
      title = "后台管理"
      if (token = env.params.body["token"]?) && (user_id = DB.find_user_by_token(token.strip))
        groups = DB.managed_groups(user_id) || Array(String).new
        render "src/views/admin.html.ecr", "src/views/layout.html.ecr"
      else
        error_msg = "Login failed"
        render "src/views/login.html.ecr", "src/views/layout.html.ecr"
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
end
