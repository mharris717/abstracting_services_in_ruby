# !SLIDE :index 200
# Sample Service
# 

require 'asir'

# Added logging and #client support.
module SomeService
  include SI::Client # SomeService.client
  include SI::Log    # SomeService#_log_result

  def do_it x, y
    _log_result [ :do_it, x, y ] do 
      x * y + 42
    end
  end
  def do_raise msg
    raise msg
  end
  extend self
end
# !SLIDE END
