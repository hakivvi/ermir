require_relative 'transport_constants'
module Ermir
  module Utils
    module_function
    def stream_header_valid?(stream)
      stream[0..3].unpack("L>")[0].eql?(Ermir::TransportConstants::OBJECT_STREAM_MAGIC)
    end

    def error_and_abort!(error_msg, at, other_error_msg=nil)
      msg = "Error [#{at}]: #{error_msg[-1].eql?(?.) ? error_msg[...-1] : error_msg}.".red
      msg += "\n#{' '*4}|_ #{other_error_msg[-1].eql?(?.) ? other_error_msg[...-1] : other_error_msg}." if other_error_msg
      abort(msg)
    end
    def print_time_msg(msg, color=nil)
      puts "[#{Time.now.strftime('%I:%M:%S')}] #{msg}".public_send(color&.to_sym||:itself)
    end
    def print_rmi_transport_msg(msg, peeraddr, color=nil)
      puts "[remote-peer-#{[peeraddr[-1], peeraddr[1]].join(':')}] #{msg}".public_send(color&.to_sym||:itself)
    end
  end
end