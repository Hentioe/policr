require "./config/*" # with requiring jennifer and her adapter
require "./db/migrations/*"
require "sam"
load_dependencies "jennifer"
load_dependencies "digests"

# your custom tasks here
Sam.help
