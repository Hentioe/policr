module Policr
  COMMIT  = {{ `git rev-parse --short HEAD`.stringify.strip }}
  VERSION = "0.2.0-dev (#{COMMIT})"
end
