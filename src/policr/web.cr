require "kemal"
require "kemal-session"
require "markd"

module Policr::Web
  extend self

  class Section
    getter prefix : String
    getter title : String
    getter anchor : String
    getter content : String

    def initialize(@prefix, @title, @anchor)
      content = File.read("texts/#{@prefix}_#{anchor}.md")
      content = render content, ["version", "torture_sec"], [VERSION, DEFAULT_TORTURE_SEC]
      @content = Markd.to_html content
    end
  end

  class PageContent
    getter prefix : String
    getter title : String
    getter subtitle : String
    getter sections : Array(Section)

    def initialize(@prefix, @title, @subtitle, @sections = Array(Section).new)
    end

    def <<(title : String, anchor : String)
      sections << Section.new @prefix, title, anchor
      self
    end
  end

  QA_PAGE = PageContent.new("qa", "快速入门", "通过本页，让机器人工作起来")
    .<<("审核具体指的什么？", "examine")
    .<<("为什么加群要验证？", "verification")
    .<<("哪种验证方式最好？", "best_verification")
    .<<("为什么要针对清真？", "halal")
    .<<("举报的益处有什么？", "report")
    .<<("验证失败不是真人？", "verification_failure")
    .<<("验证失有什么后果？", "verification_failure_result")
    .<<("不限时验证的害处？", "no_time_limit")
    .<<("解释何为记录模式？", "record_mode")
    .<<("解释何为干净模式？", "clean_mode")
    .<<("定制验证最佳实践？", "best_custom")
    .<<("为何建议信任管理？", "trust_admin")
    .<<("不信任能使用按钮？", "distrust_button_use")
    .<<("来源调查功能意义？", "from")
    .<<("白名单范围有多大？", "whitelist")
    .<<("内联键盘干嘛失效？", "inline_keyboard_invalid")
    .<<("为何突然事后审核？", "afterwards")
    .<<("订阅全局规则好处？", "global_rules")

  ADVANCED_PAGE = PageContent.new("adv", "高级教程", "通过本页，了解更深层的使用方式")
    .<<("仅限制而不封禁用户", "only_restriction")
    .<<("无错验证的设置方式", "unable_error")
    .<<("欢迎消息，贴纸模式", "sticker_mode")

  def home_page?(env : HTTP::Server::Context)
    env.request.path == "/"
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
      page = QA_PAGE
      title = page.title
      render "src/views2/doc.html.ecr", "src/views2/layout.html.ecr"
    end

    get "/advanced" do |env|
      page = ADVANCED_PAGE
      title = page.title
      render "src/views2/doc.html.ecr", "src/views2/layout.html.ecr"
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
