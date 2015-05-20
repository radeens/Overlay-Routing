require 'socket'
require_relative 'client_socket.rb'
require_relative 'message_handling.rb'
require_relative 'security.rb'

class Server
	@@visited_keys = []
	def self.listen()
		server = TCPServer.new 9042
		threads = []
		loop do
	  		Thread.start(server.accept) do |client|
	  			frame = ""
	  			while fr = client.gets
	  				frame << fr
	  			end
	  			
	  			type,sq_num,packet = frame.split(/:/)


	  			if type == "KEY"
	  				if ! @@visited_keys.include? sq_num
		  				n, k = packet.split(/,/)
		  				@@public_keys.store(n,k)
		  				@@visited_keys << sq_num
		  				Client.send_to_neighbors(packet,sq_num,"")
		  			end

	  			else 
		  			if ! @@visited_sq_nums.include? sq_num
		  				graph  = eval("#{packet}")
		  				sender = graph.keys[0]
		  				@@visited_sq_nums << sq_num
		  				$topology.add_vertex(sender,graph[sender])
		  				Client.send_to_neighbors(packet,sq_num,"")
		  			end
		  		end
	  			client.close
	  		end #--end-thread
		end #--end loop
		threads.each{ |t|
			t.join
		}
	end #--end method

	def self.listen1 (node)
		server = TCPServer.new 9043
		loop do
	  		Thread.start(server.accept) { |client|
	  			#frame = [type,sq_num,dest_node,senderIp,frag,msg]
	  			@frame = eval(client.gets)  # read the arriving frame
	  			if @frame[0] == "SEC"		#SEC|nextnode|encrypted
	  				msg = @frame[1]
	  				msg = Secure.decrypt(msg)
	  				if msg.include? "DST"
	  					MessageHandle.handle_secure(node,msg)
	  				else
	  					nextHopNode = msg
	  					nextHopIp 	= @@neighbors_interfaces[nextHopNode]
	  					@frame.shift
	  					@frame.shift
	  					@frame.unshift "SEC"
	  					Client.send(@frame.to_s,nextHopIp)
	  				end


	  			end

	  			dest = @frame[2]
	  			if(dest == node) # if current node is the destination node
	  				MessageHandle.handle_output(node,@frame)
	  				
	  			else
	  				if(@frame[0]==3 && (@frame[0]!=4)) # traceroute protocol send back the ack
	  					MessageHandle.send_trace_ack(node,@frame,3)
	  				#elsif (@frame[])
	  				end
	  				nextHopNode = @@routing_table[dest][1]
	  				nextHopIp 	= @@neighbors_interfaces[nextHopNode]
	  				Client.send(@frame.to_s,nextHopIp)
	 
	  			end
	  			client.close
	  		}
	  	end #--end loop
	end #--end method
end #--end class