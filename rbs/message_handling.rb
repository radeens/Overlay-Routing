require_relative 'client_socket.rb'

class MessageHandle
	@data = []	# fragement buffer
	@frame = [] # frame buffer

	# Send the acks using client services
	def self.send_ack(frame,type,data)
		s, dest_node = frame[1].split(/:/)
		nextHopNode  = @@routing_table[dest_node][1]
	  	nextHopIp 	 = @@neighbors_interfaces[nextHopNode]
	  	#ack = [ack|seq_num|origin|acksender|type|data]
		ack = [4,frame[1],dest_node,frame[3],type,data]
		Client.send(ack.to_s,nextHopIp)
	end

	# handle the acks for TRACEROUTE
	def self.send_trace_ack(node,frame,type)
		s, dest_node = frame[1].split(/:/)
		nextHopNode  = @@routing_table[dest_node][1]
	  	nextHopIp 	 = @@neighbors_interfaces[nextHopNode]
	  	#ack = [ack|seq_num|origin|type|data]
	  	nodeip = @@neighbors_interfaces[node]
		ack = [4,frame[1],dest_node,nodeip,type,frame[3]]
		Client.send(ack.to_s,nextHopIp)

	end

	# Handle the ackknowledgements
	def self.handle_ack(frame)
		protocol = frame[4]
		if(protocol == 1)
			puts "Message sent!"
		elsif (protocol == 2) #ping
			time  = Time.now-@@timer[frame[1]]
			if(time<(5*1000))
				size = frame[5].size
				puts "#{size} bytes from #{frame[3]}: seq_num:
				#{frame[1].split[0]} in #{(time*1000).round(4)} ms"
			else
				puts "PING ERROR: HOST UNREACHABLE"
			end
		else
			time  = Time.now-@@timer[frame[1]]
				if (time < 2*1000)
					puts ">>\t\t#{time.round(4)} ms\t\t#{frame[3]}"
					sleep(1)
				else 
					puts ">>\t\t*\t\t*\t\tReuest timeout!"
					sleep(1)
				end
		end
	end

	def self.handle_msg()
		if(@frame[4] == 0)
				puts "RECEIVED MSG #{@frame[3]} #{@frame[5]}"
				send_ack(@frame,1,"");
			elsif(@frame[4]=="end")
				@data << @frame[5]
				puts "RECEIVED MSG #{@frame[3]} #{@data.join}"
				@@visited_sq_nums << @frame[1]
				@data = []
				send_ack(@frame,1,"");
			else
				@data << @frame[5]
			end
	end

	# Handle Secure Messages
	def self.handle_secure(node, frame)
			frame.slice!(frame.size-1)
			frame.slice!(frame.size-1)
			frame = frame.split(':')
			puts "RECEIVED SECURE MSG #{frame[1]} #{frame[2]}"
	end


	def self.handle_output(node,frame)
		@frame = frame
		type = @frame[0]
		if(type == 1) #SENDMSG
			handle_msg();

		elsif(type == 2) # PING
			send_ack(frame,2,@frame[4])
			
		elsif(type == 3) # TRACEROUTE
			send_trace_ack(node,frame,3)

		else #ACK
			handle_ack(frame)
		end
	end
end