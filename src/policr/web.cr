require "kemal"
require "kemal-session"
require "markd"

module Policr::Web
  extend self

  class QA
    getter title : String
    getter anchor : String
    getter content : String

    def initialize(@title, @anchor)
      content = File.read("texts/qa_#{anchor}.md")
      content = render content, ["version", "torture_sec"], [VERSION, DEFAULT_TORTURE_SEC]
      @content = Markd.to_html content
    end
  end

  QA_LIST = [
    QA.new("审核具体指的什么？", "examine"),
    QA.new("为什么加群要验证？", "verification"),
    QA.new("哪种验证方式最好？", "best_verification"),
    QA.new("为什么要针对清真？", "halal"),
    QA.new("举报的益处有什么？", "report"),
    QA.new("验证失败不是真人？", "verification_failure"),
    QA.new("验证失有什么后果？", "verification_failure_result"),
    QA.new("不限时验证的害处？", "no_time_limit"),
    QA.new("解释何为记录模式？", "record_mode"),
    QA.new("解释何为干净模式？", "clean_mode"),
    QA.new("定制验证最佳实践？", "best_custom"),
    QA.new("为何建议信任管理？", "trust_admin"),
    QA.new("不信任能使用按钮？", "distrust_button_use"),
    QA.new("来源调查功能意义？", "from"),
    QA.new("白名单范围有多大？", "whitelist"),
    QA.new("内联键盘干嘛失效？", "inline_keyboard_invalid"),
    QA.new("为何突然事后审核？", "afterwards"),
    QA.new("订阅全局规则好处？", "global_rules"),
  ]

  def home_page?(env : HTTP::Server::Context)
    env.request.path == "/beta"
  end

  def start(port : Int, prod : Bool, bot : Bot)
    serve_static({"gzip" => false})
    public_folder "static"
    Kemal.config.logger = LoggerHandler.new(Logging.get_logger)

    Kemal::Session.config do |config|
      config.secret = "demo_sec"
    end

    get "/" do |env|
      title = "专注于审核的 Telegram 机器人"
      render "src/views2/index.html.ecr", "src/views2/layout.html.ecr"
    end

    get "/getting-started" do |env|
      title = "快速入门"
      render "src/views2/getting-started.html.ecr", "src/views2/layout.html.ecr"
    end

    get "/qa" do |env|
      title = "常见问题"
      render "src/views2/qa.html.ecr", "src/views2/layout.html.ecr"
    end

    get "/traditional" do
      title = "专注于审核的 Telegram 机器人（已过时页面）"
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
        if user_id = nil || token == bot.token
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
        "???"
      else
        env.redirect "/login"
      end
    end

    get "/version" do
      VERSION
    end

    error 404 do
      "瞎访问啥呢你……"
    end

    Kemal.config.env = "production" if prod
    Kemal.run(args: nil, port: port)
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
