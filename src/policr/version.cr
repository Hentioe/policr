module Policr
  COMMIT  = {{ `git rev-parse --short HEAD`.stringify.strip }}
  VERSION = "0.1.5-dev (#{COMMIT})"
end
