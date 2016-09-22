class Watcher
	require 'filewatcher'
	require 'nokogiri'
	require 'net/http'
	require 'json'
	# require 'uri'
	require 'pathname'

	attr_accessor :path

	def initialize(path: '/Users/grep/workspace/development/grep/public/images/**/*.xml')
		@path = path.to_s
	end

	def filewatcher_init
		@filewatcher = FileWatcher.new(["/Users/grep/workspace/development/grep/public/images/**/*.xml"]) # **/*.xml
	end

	def filedescriptor_setup
		log_path = "watcher.log"
		$stdout.reopen(log_path, "w")
		$stdout.sync = true
		$stderr.reopen($stdout)
	end

	def daemon_init
		Process.daemon(true,true)
		# write pid to a .pid file ps -p pid
		pid_file = File.dirname(__FILE__) + "#{__FILE__}.pid"
		File.open(pid_file, 'w') { |f| f.write Process.pid }
	end

	def watcher_start

		@filewatcher.watch() do |filename, event|

			unless(event == :delete)
				path = Pathname.new(filename)
				puts "File updated: " + filename
				# filename = File.join(Pathname.new('/Users/grep/workspace/development/grep/public/images/').realpath.to_s, path.basename.to_s)
				xml_parser(filename)
				# ocr_server_post
			end

			# path = Pathname.new(filename)
			# puts "Basename         : " + path.basename.to_s
			# puts "Relative filename: " + File.join(Pathname.new('.').to_s, path.to_s)
			# puts "Absolute filename: " + File.join(Pathname.new('.').realpath.to_s, path.to_s)
		end
	end

	def xml_parser(path)
		# File.read("/Users/grep/workspace/test/ruby/filewatcher_ruby/xml_01.xml")
		
		xml_file = File.read(path)

		xml = { text: [], left: [], top: [], right: [], bottom: [] }

		Nokogiri::XML.parse(xml_file).remove_namespaces!.xpath('//line').each do |elements|
			result = { 
				path: path,
				text: elements.text, 
				left: elements.attribute("l").text, 
				top: elements.attribute("t").text, 
				right: elements.attribute("r").text, 
				bottom: elements.attribute("b").text }

			ocr_server_post(result)

		end

		# unless xml.nil?
		# 	xml.each_value do |value|
		# 		value.each do |result|
		# 			puts "#{result}"
		# 		end
		# 	end
		# end
	end

	def ocr_server_post(data)
		begin
			params = URI.encode_www_form( { 
				path: 		"#{data[:path]}", 
				text: 		"#{data[:text]}", 
				left: 		"#{data[:left]}", 
				top: 		"#{data[:top]}", 
				width: 		"#{data[:right]}", 
				height: 	"#{data[:bottom]}"} )

			uri = URI.parse("http://127.0.0.1:3000/ocr/parser?#{params}")
			req = Net::HTTP::Get.new(uri.request_uri)

			# req = Net::HTTP::Post.new(uri.path)
			# req.set_form_data({ 
			# 	'path'		=> "#{data[:path]}", 
			# 	'text'		=> "#{data[:text]}", 
			# 	'left'		=> "#{data[:left]}", 
			# 	'top'		=> "#{data[:top]}", 
			# 	'right' 	=> "#{data[:right]}", 
			# 	'bottom'	=> "#{data[:bottom]}" }, ';')
			
			res = Net::HTTP.start(uri.host, uri.port) do |http|
			  http.request(req)
			end
			
			case res
			when Net::HTTPSuccess, Net::HTTPRedirection
				
			else
				puts "[ERROR::#{Time.now}] #{res.error!}"
			end

		rescue => e
			puts "[ERROR::#{Time.now}] #{e.message}"
			puts "\n"
		end
	end

	def start
		filedescriptor_setup
		filewatcher_init
		watcher_start
	end

	def end
		@filewatcher.end
	end

end