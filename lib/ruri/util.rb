module Ruri
  module Util
    PAGER = 'less -R -f'
    class << self
      def less(str = nil)
        Tempfile.open('jugyo_is_very_cool') do |file|
          yield file if block_given?
          file << str if str
          file.flush
          system "#{PAGER} #{file.path}"
        end
      end
    end
  end
end

command 'eval', <<HELP do |arg|
Eval as ruby script
HELP
  p eval(arg, binding, __FILE__, __LINE__) unless arg.empty?
end

command 'irb', <<HELP do |arg|
Start irb
HELP
  require 'irb'
  IRB.start
end
