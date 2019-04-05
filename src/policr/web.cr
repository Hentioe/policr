require "kemal"

module Policr::Web
  extend self

  def start
    config = CLI::Config.instance
    serve_static({"gzip" => false})
    public_folder "public"

    get "/" do
      "Hello Policr!"
    end

    Kemal.config.env = "production" if config.prod
    Kemal.run(args: nil, port: config.port)
  end
end
