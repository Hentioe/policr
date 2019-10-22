require "clicr"

module Policr::CLI
  macro def_action(action, exclude = false)
    def cli_run
      Clicr.create(
        name: "policr",
        info: "A Telegram bot",
        action: {{action}},
        variables: {
          port: {
            info:     "Web server port",
            default:  8080,
          },
          llevel: {
            info:     "Log level",
            default:  "info",
          },
          dpath: {
            info:     "Data directory path",
            default:  "./data",
          }
        },
        options: {
          prod: {
            info:     "Running in prod mode",
          },
          oweb: {
            info:     "Only web server"
          }
        }
      )
    end

    begin
      cli_run unless {{exclude}}
    rescue ex : Clicr::Help
      puts ex; exit 0
    rescue ex : Clicr::ArgumentRequired | Clicr::UnknownCommand | Clicr::UnknownOption | Clicr::UnknownVariable
      abort ex
    rescue ex
      raise ex
    end
  end
end
