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

    get "/admin" do
      title = "后台管理"
      render "src/views/admin.html.ecr", "src/views/layout.html.ecr"
    end

    error 404 do
      "建设中……"
    end

    Kemal.config.env = "production" if config.prod
    Kemal.run(args: nil, port: config.port)
  end
end
