module Policr
  COMMIT  = {{ `git rev-parse --short HEAD`.stringify.strip }}
  VERSION = "0.1.4-dev (#{COMMIT})"
end
