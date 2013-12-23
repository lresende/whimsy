require File.expand_path('../main.rb', __FILE__)

require '/var/tools/asf/rack'

# https://svn.apache.org/repos/infra/infrastructure/trunk/projects/whimsy/asf/rack.rb
use ASF::Auth::MembersAndOfficers
use HTTPS_workarounds

run Sinatra::Application