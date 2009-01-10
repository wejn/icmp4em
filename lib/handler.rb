module ICMP4EM

  module Handler
    
    include Common

    def initialize(socket)
      @socket = socket
    end

    def notify_readable
      receive(@socket)
    end
    
    def unbind
      @socket.close if @socket
    end
    
    private

    def receive(socket)
      # The data was available now
      time = Time.now
      # Get data
      host, data = read_socket(socket)
      # Rebuild message array
      msg = data[20,30].unpack("C2 n3 A22")
      # Verify the packet type is echo reply and verify integrity against the checksum it provided
      return unless msg.first == ICMP_ECHOREPLY && verify_checksum?(msg)
      # Find which object it is supposed to go to
      recipient = ICMPv4.instances.find{|x| x.id == msg[3]}
      # Send time and seq number to recipient object
      recipient.send(:receive, [time, msg[4]]) unless recipient.nil?
    end

    def read_socket(socket)
      # We are only expecting a 50 byte packet (I think.)
      data, sender = socket.recvfrom(50)
      # Get the host in case we want to use that later.
      host = Socket.unpack_sockaddr_in(sender).last
      [host, data]
    end

  end

end