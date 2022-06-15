# frozen_string_literal: true
require_relative 'errors'
require_relative 'utils'
require_relative 'version'
require 'slop'
require 'slop/option'
require 'colorize'
require 'resolv'

module Ermir
  module ArgvParser
    class ::FileOption < Slop::Option
      def call(value)
        begin
          obj = File.open(value, 'rb').each_byte.to_a.pack("C*")
          unless Utils.stream_header_valid?(obj)
            Utils.error_and_abort!(Errors::FILE_CORRUPTED_ERROR, "--file")
          end
          obj
        rescue Errno::ENOENT, Errno::EACCES => e
          Utils.error_and_abort!(Errors::FILE_PATH_ERROR, "--file", e.to_s)
        end
      end
    end

    class Slop::BoolOption < Slop::Option
      alias_method :old_call, :call
      def call(*args)
        if @flags == %w[-p --pipe]
          if !$stdin.tty?
            obj = $stdin.each_byte.to_a.pack("C*")
            unless Utils.stream_header_valid?(obj)
              Utils.error_and_abort!(Errors::STDIN_CORRUPTED_ERROR, "--pipe")
            end
            obj
          else
            Utils.error_and_abort!(Errors::STDIN_EMPTY_ERROR, "--pipe")
          end
        else
          old_call(*args)
        end
      end
    end

    def self.parse_argv!
      begin
        options = Slop.parse do |opts|
          opts.banner = <<END
Ermir by @hakivvi * https://github.com/hakivvi/ermir.
Info:
#{' '*4}Ermir is a Rogue/Evil RMI Registry which exploits unsecure Java deserialization on any Java code calling standard RMI methods on it.
Usage: ermir [options]
END
          opts.banner.chomp!
          opts.string "-l", "--listen", "bind the RMI Registry to this ip and port (default: 0.0.0.0:1099).", default: "0.0.0.0:1099"
          opts.file "-f", "--file", "path to file containing the gadget to be deserialized."
          opts.boolean "-p", "--pipe", "read the serialized gadget from the standard input stream."
          opts.on "-v", "--version", "print Ermir version." do
            puts "Ermir v#{Ermir::VERSION}."
            exit
          end
          opts.boolean '-h', "--help", "print options help."
        end

        if options[:help] || ARGV.empty?
          puts "#{options}Example:\n#{' '*4}$ gadgetmarshal /path/to/ysoserial.jar Groovy1 calc.exe | ermir --listen 127.0.0.1:1099 --pipe"
          exit
        end

        args = options.to_hash.map{|k,v| k.eql?(:listen) ? [k] << v.rpartition(":").then{|i,_,p| [i, p.to_i]} : [k,v]}.to_h

        if [::Resolv::IPv4::Regex, ::Resolv::IPv6::Regex].none? {args[:listen][0] =~ _1} or !args[:listen][1].between?(1, 0xffff)
          Utils.error_and_abort!("the provided bind IP address or port is not valid.", "--listen")
        end

        if args[:file] && args[:pipe]
          puts "[NOTE] the serialized gadget is provided via both (--file) and (--pipe), prioritizing pipe.".magenta
        elsif args[:file].nil? && !args[:pipe]
          Utils.error_and_abort!(Errors::GADGET_NOT_PROVIDED, "options")
        end
        [args[:listen].first, args[:listen].last, args[:pipe] || args[:file]]
      rescue Slop::UnknownOption, Slop::MissingArgument => e
        Utils.error_and_abort!(e.to_s, "options")
      end
    end
  end
end