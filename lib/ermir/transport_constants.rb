# frozen_string_literal: true
module Ermir
  # from: sun.rmi.transport.TransportConstants.java
  module TransportConstants
    # Transport magic number: "JRMI"
    MAGIC = 0x4a524d49
    # Transport version number
    VERSION = 2

    # Connection uses stream protocol
    STREAM_PROTOCOL = 0x4b
    # Protocol for single operation per connection no ack required
    SINGLE_OP_PROTOCOL = 0x4c
    # Connection uses multiplex protocol
    MULTIPLEX_PROTOCOL = 0x4d

    # Ack for transport protocol
    PROTOCOL_ACK = 0x4e
    # Negative ack for transport protocol (protocol not supported)
    PROTOCOL_NACK = 0x4f

    # RMI call
    CALL = 0x50
    # RMI return
    RETURN = 0x51
    # Ping operation
    PING = 0x52
    # Acknowledgment for Ping operation
    PING_ACK = 0x53
    # Acknowledgment for distributed GC
    DGC_ACK = 0x54

    # Normal return (with or without return value)
    NORMAL_RETURN = 0x01
    # Exceptional return
    EXCEPTIONAL_RETURN = 0x02

    INTERFACE_STUB_HASH = 4905912898345647071
    INTERFACE_SKEL_HASH = 4905912898345647071

    OBJECT_STREAM_MAGIC = 0xACED0005
    TC_BLOCKDATA = 0x77
    TC_STRING = 0x74
    TC_CLASSDESC = 0x72
    TC_PROXYCLASSDESC = 0x7d
    TC_ENDBLOCKDATA = 0x78
    TC_NULL = 0x70
    TC_REFERENCE = 0x71
    TC_OBJECT = 0x73
    TC_ARRAY = 0x75
    TC_CLASS = 0x76
    TC_RESET = 0x79
    TC_BLOCKDATALONG = 0x7A
    TC_EXCEPTION = 0x7B
    TC_LONGSTRING =  0x7C

    SC_WRITE_METHOD = 0x01
    SC_BLOCK_DATA = 0x08
    SC_SERIALIZABLE = 0x02
    SC_EXTERNALIZABLE = 0x04
    SC_ENUM = 0x10


    OPS = {0 => "bind", 1 => "list", 2 => "lookup", 3 => "rebind", 4 => "unbind"}
  end
end