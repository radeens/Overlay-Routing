require 'socket'

class Client
	# class method
	def self.send_to_neighbors(packet, sq_num, except)
		threads = Array.new
		@@neighbors_interfaces.values.each { |neighbor|
				Thread.start{ 
					n = TCPSocket.new neighbor, 9042
					if sq_num.include?"K"
						frame = "KEY:#{sq_num}:#{packet}"
					else
						frame = "HELLO:#{sq_num}:#{packet}"
					end
					n.puts frame
					n.close
				}
		}
		threads.each{|t|
			t.join
		}
	end #end method

	def self.send(frame,nextHopIp)
			n = TCPSocket.new nextHopIp, 9043
			n.puts frame
			n.close
	end #end method

end # end class