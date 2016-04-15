#!/usr/bin/env ruby

require 'erb'

init_methods = []

# Find source code in these two subdirs.
Dir.glob("{#{ARGV.join(',')}}/**/*.{c,cu}").each do |fn|
	File.open(fn, 'r') do |f|
		parse_decl = false
		name = nil
		decl = nil
		f.each_line do |line|
			if line.start_with? '//@ccv_nnc_init'
				parse_decl = true
				name = line[15..-1].strip
			elsif parse_decl
				# Parse this line to the method symbol
				matchdata = /^\s*void\s+([\w\_]+)/.match line.strip
				if matchdata != nil
					decl = matchdata[1]
					init_methods << {:name => name, :decl => decl}
				else
					parse_decl = false
					name = nil
					decl = nil
				end
			end
		end
	end
end

init_methods.sort! do |x, y|
	x[:name] <=> y[:name]
end

def rendering(init_methods)
	init = ERB.new File.read('ccv_nnc_init.inc.erb')
	return init.result binding
end

rendered_init = rendering(init_methods)

existing_init = File.read 'ccv_nnc_init.inc' if File.exist? 'ccv_nnc_init.inc'

if existing_init != rendered_init
	File.open('ccv_nnc_init.inc', 'w+') do |f|
		f.write rendered_init
	end
end
