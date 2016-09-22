class WatcherController
	require './watcher.rb'
	require 'optparse'

	OPTS = Hash.new

	parser = OptionParser.new
	parser.version = '0.0.1 [test version]'
	parser.on('-c path', '--path') {|v| OPTS[:c] = v}
	
	parser.parse!(ARGV)

	Process.daemon(true,true)
	# write pid to a .pid file ps -p pid
	pid_file = File.dirname(__FILE__) + "#{__FILE__}.pid"
	File.open(pid_file, 'w') { |f| f.write Process.pid }

	watcher = Watcher.new

	# watcher.daemon_init
	watcher.start
end