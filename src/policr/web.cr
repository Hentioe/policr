require "kemal"

module Policr::Web
  extend self

  def start
    config = CLI::Config.instance
    serve_static({"gzip" => false})
    public_folder "public"

    get "/" do
      render "src/views/index.ecr"
    end

    Kemal.config.env = "production" if config.prod
    Kemal.run(args: nil, port: config.port)
  end
end
