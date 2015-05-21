############################################################
# OverLay Routing Protocol on Core Emulator                #							
# Send Message, Ping, Traceroute 						   #
# Secure Messaging Using RSA:1024                          #
############################################################
require 'socket'
require 'openssl'
require_relative 'client_socket.rb'
require_relative 'server_socket.rb'
require_relative 'message_handling.rb'
require_relative 'graph.rb'
require_relative 'security.rb'


# PARSE THE config_file & SAVE THE VARIABLES 
def parse_config
    $mtu	= @config_file.gets.chomp.split[1]
    @interval 	= @config_file.gets.chomp.split[1]
    @dump_int	= @config_file.gets.chomp.split[1]
    @costs_path	= @config_file.gets.chomp.split[1]
    @table_file	= @config_file.gets.chomp.split[1]
    @nta_path	= @config_file.gets.chomp.split[1]
    @atl_path	= @config_file.gets.chomp.split[1]
    @wakeup	= @config_file.gets.chomp.split[1]
end

# GET ALL MY IPS
def get_my_Ips
	file = File.open(@nta_path, 'r')
	while line = file.gets
    	x,y = line.split	
    	if x == @node
        	@my_ips << y
    	end   
	end
	file.close
end

# GET THE NODE FOR THE IP
def get_Node(ip)
	file = File.open(@nta_path, 'r')
	while line = file.gets
		node,file_ip = line.split
		if ip == file_ip
			break
		end
	end
	file.close
	return node
end

# GET IP OF MY LINK GOING TO THE NEXT HOP
def get_my_Ip(nextHopIp)
	file = File.open(@atl_path, 'r')
	while line = file.gets
	    	myip,nebor = line.chomp.split	
	    	if nebor == nextHopIp
	    		file.close
			return myip
	    	elsif myip == nextHopIp
	    		file.close
	    		return nebor
	    	end   
	end
end

# GET THE OUTGOING COST TO THE NEIGHBORS
def get_outgoing_cost
	#open cost file genererated by gen_weights.
	file = File.open(@costs_path, 'r')
	
	links = Hash.new
	links[@node] = Hash.new

	while line = file.gets
		x,y,z,@s= line.split(/,/)		#host_ip neighborIP cost sq_num

		if @my_ips.include? x			#if this ip is for node
			y_node = get_Node(y)
			@@neighbors_interfaces.store(y_node, y) #neighbornode and ip
			@@neighbors_interfaces.store(get_Node(x),x)
			links[@node].store(y_node,z.chomp)
		end
	end
	@outgoing_packets[@node] = links[@node]
	$topology.add_vertex(@node, links[@node])
	file.close
end

# SENDS THE PUBLIC KEYS TO ALL OTHER NODES
def send_keys()
	new_public = ""
	new_public << "#{@@new_key.public_key.to_s}"
	packet = "#{@node},#{new_public}"		# node => key
	Client.send_to_neighbors(packet,"K-#{@node}", "")
	sleep(10)
end

# CREATES ROUTING PERIODICALLY
def create_routing()
	num = 0
	while(true)
			
		sq_num = "#{@node}#{num}"
		@@visited_sq_nums << sq_num

		num+=1

		Client.send_to_neighbors(@outgoing_packets, sq_num, "")

		sleep(10) # SLEEP FOR CONVERGENCE

		@@routing_table = $topology.get_routing(@node)

		puts "Routing updated! #{@@routing_table}"
		puts "System ready, start typing your messages!"

		out_file = File.open("#{@table_file}#{@node}.txt", "w")

		out_file.puts("Source\t\tDest\t\tNextHop\t\tCost\t\tSq_Num")
		@@routing_table.each{|key,val|
		out_file.puts(" #{val[0]}\t\t #{key}\t\t #{val[1]}\t\t #{val[2]}\t\t #{@s}")
		}
		out_file.flush
		out_file.close

		time = Time.now
		while(true)
			file = File.open("#{@costs_path}","r")
		    lines = file.readlines
		    
		    lines.each{ |line|
		        x,y,z,@s1 = line.split(/,/)
		    }
		    if @s != @s1 
		        get_outgoing_cost()
		        break
		    end
		    sleep(@interval.to_i) #update_interval
		end	#inner while end
	end #outer while end

	@config_file.close

end

# GLOBAL AND CLASS VARIABLES
def initialize_global()
	$mtu 		= 0				# max bytes initialized 
	$topology	= Graph.new 			# topology of the network

	@@routing_table = {}				# dest=>{origin nexthop cost sq}
	@@neighbors_interfaces= Hash.new		# outgoint interfaces to node
							# node => ip
	@@visited_sq_nums = Array.new 			# visited packets

	@@new_key	= OpenSSL::PKey::RSA.new 1024
	@@public_keys	= Hash.new 		# public keys of the all the nodes

end


#------------ main() -----------------------------------------------------

#instance variables
if ARGV[0]
	config_path	= ARGV[0]		# config file path = get from args
	@config_file= File.open(config_path,'r')# config File open
else 
	puts "USAGE: <node.rb> <config_file.txt>"
	abort("USAGE ERROR!")
end

@node 		= Socket.gethostname  		# get the hostname
@my_ips		= Array.new 			# ips of the current node
@outgoing_packets = Hash.new			# graph of neighbors

initialize_global()				# INIT GLOBALS
parse_config()					# parse global_config file
get_my_Ips()					# get all my ips
get_outgoing_cost()

@config_file.close

timer = -1					# do not start

while (true)
	if @node != "n12"
		file = File.open(@wakeup, "r")
		timer = file.gets.to_i
	else 
		file = File.open(@wakeup, "w")
		file.puts("0")
		timer = 0
	end
	if timer == -1
		next;
	else
		file.close
		break;
	end	
end

# start listening topology server
t1 = Thread.start{
	Server.listen();
}

# sleep so others can wake up
sleep (5) 
puts "Everybody is up!"

# for next start put -1
if @node == "n12"
	file = File.open(@wakeup, "w")
	file.puts("-1")
	file.close
end

# control message server
t2 = Thread.start{
	Server.listen1(@node);
}
# send the RSA public keys
t3 = Thread.start{
	send_keys();
}

# create_routing table
t4 = Thread.start{
	create_routing();
}


# control messaging protocols
puts "Please wait, system initializing..."
sec_num = 0
$mtu = $mtu.to_i-8 #MAXIMUM TRANSMISSION UNIT
while f = $stdin.gets
	protocol = (f.chomp).split(" ",3)
	type = protocol[0]						# Control
	dest = protocol[1]						# DEST IP
	data = protocol[2]						# input data
	dest_node = get_Node(dest)					# DEST NODE
	if !@@routing_table[dest_node]				
		puts "#{type} ERROR: HOST UNREACHABLE"
		next
	else
		nextHopNode = @@routing_table[dest_node][1] # get next hop for the dest
	end
	
	nextHopIP = @@neighbors_interfaces[nextHopNode]				
	my_ip = get_my_Ip(nextHopIP)				# my_ip for the nexthop link

	sequence = "#{sec_num}:#{@node}"			# sec_num
	sec_num+=1

	if(type == 'SENDMSG')
		#frame = [type|sq_num|dest|senderIp|frag|msg]
		header = [1,sequence,dest_node,my_ip]
		#print "#{nextHopIP}"
		#print "#{my_ip}"
		header_size = (header.to_s).size
		msg_size	= (data.to_s).size
		total_size 	= (header_size+msg_size)
		if(total_size > $mtu)
			frag_num = 1
			while(msg_size > 0)
				packsize = $mtu.to_i-header_size-frag_num.to_s.size
				packet = data.slice(0,packsize)
				data   = data.slice(packsize,data.to_s.size)
				frame  = header.clone
				frame << frag_num.to_s
				frame << packet
				puts frame.to_s.size
				Client.send(frame.to_s,nextHopIP)
				msg_size = data.to_s.size
				if(msg_size < packsize)
					frag_num = "end"
				else
					frag_num += 1
				end
			end
		else
			frame = header
			frame << 0
			frame << data
			Client.send(frame.to_s, nextHopIP)
		end

	elsif (type == 'PING')
		@@timer = {}
		data = data.split
		numpings = data[0].to_i
		delay = data[1].to_i
		pingdata = "thisisapingmessage"
		num = 0
		puts "pinging #{dest} with 18 bytes of data"
		while(num < numpings)
			#frame = [type|seq|destNode|dest_ip|data]
			frame = [2,"#{num}:#{@node}",dest_node,dest,pingdata]
			@@timer[frame[1]] = Time.now
			Client.send(frame.to_s,nextHopIP)
			num+=1
			sleep(delay)
		end
		
	elsif (type == 'TRACEROUTE')
		@@timer = {}
		data = "traceroutemessages"
		puts "Tracing route to #{dest}, max #{30} hops"
		puts "  with #{data.size} byte packet"
		@@timer[sequence]= Time.now
		frame =[3,sequence,dest_node,data]
		Client.send(frame.to_s,nextHopIP)

	# Secure messaging SSENDMSG IP MSG
	# Does not handle the messages > MTU
	elsif(type == 'SSENDMSG')
		msg = ["DST:#{my_ip}:#{data}"]
		#frame = [type|sq_num|dest|senderIp|frag|msg]
		path = $topology.shortest_path(@node, dest_node)
		node = path.shift
		key = @@public_keys[node]
		msg = [Secure.encrypt(key,msg.to_s)]

		while path.size > 0		#[Nextnode|"E[DST|my_ip|data]"]
			key = path.first
			key = @@public_keys[key]
			enc_Node = Secure.encrypt(key,node)
			msg.unshift enc_Node 
			node = path.shift
		end

		msg.unshift "SEC"
		Client.send(msg.to_s,nextHopIP)

	end
end

t1.join
t2.join
t3.join
t4.join

