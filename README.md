#Overlay Routing Protocol

Resources required:
		>> Core Emulator
		>> Ruby 1.9.3 or greater

License:
	This softwere can not be modified for for commercial redistribution purposes
	unless otherwise specified and can be fully modified for the sole purpose of the user.

How to use this softwere:
		
	1.Download the zip file.
	2.Extract the zip file to "/home/core/" folder.


	3.Running the program:
		1. Open terminal and cd to "/home/core/"
		2. Run gen_weight.rb as 
			<ruby /path/to/gen_weights.rb ~/addrs-to-links.txt ~/cost_file.txt interval>
		3. Open the core emulator
		4. Open the .imn file in core emulator and run the network
		5. Use Run-Tool to run node.rb as following:
			"/home/core/ov-lay/test.sh"
			
	Note: if the run tool do not work, the node.rb should be run on each node sequentially
	(use following process)

		WITH RUBY COMMAND--->
		- cd into the ov-lay folder for each node terminal
		- Run 
		"ruby /home/core/ov-lay/rbs/node.rb /home/core/ov-lay/configs/run_config/global_config.txt" 
			
		for each node terminal

		OR

		WITH TEST.SH COMMAND--->
		- cd into the ov-lay folder for each node terminal
		- Run "./test.sh" file for each node




