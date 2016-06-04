#!/usr/bin/env ruby
# encoding: utf-8

# Users can pass "nvim" as a first argument to use neovim.
vim = ARGV.first || 'vim'
puts "Testing #{vim} performance..."

PLOT_WIDTH = 120
LOG = "vim-plugins-profile.#{$$}.log"

VIMFILES_DIR = vim == "nvim" ? File.join(ENV['XDG_CONFIG_HOME'], 'nvim') : File.join(ENV['HOME'], '.vim')
puts "Assuming your vimfiles folder is #{VIMFILES_DIR}."

puts "Generating #{vim} startup profile..."
system(vim, '--startuptime', LOG, '-c', 'q')

# detect plugin manager
plug_dir=""
if File.directory? File.join(VIMFILES_DIR, 'plugged')
  puts "vim-plug has been detected."
  plug_dir="plugged"
elsif File.directory? File.join(VIMFILES_DIR, 'bundle')
  puts "NeoBundle/Vundle/Pathogen has been detected."
  plug_dir="bundle"
else
  puts "Cannot tell your plugin-manager. Adjust this script to meet your own needs for now."
  puts "Cue: `plug_dir` variable would be a good starting place."
  exit 1
end

# parse
exec_times_by_name = Hash.new(0)
lines = File.readlines(LOG).select { |line| line =~ /sourcing.*#{Regexp.escape(plug_dir)}/ }
lines.each do |line|
  trace_time, source_time, exec_time, _, path = line.split(' ')
  relative_path = path.gsub(File.join(VIMFILES_DIR, plug_dir) + '/', '')
  name = File.basename(relative_path.split('/')[0], '.vim')
  time = exec_time.to_f
  exec_times_by_name[name] += time
end

# plot
max = exec_times_by_name.values.max
relatives = exec_times_by_name.reduce({}) do |hash, (name, time)|
  hash.merge!(name => time/max.to_f)
end
max_name_length = relatives.keys.map(&:length).max
puts
Hash[ relatives.sort_by { |k, v| -v } ].each do |name, rel_time|
  time = exec_times_by_name[name]
  puts "#{name.rjust(max_name_length)}: (#{time.round(3).to_s.ljust(5)}ms) #{'*' * (rel_time*PLOT_WIDTH)}"
end

File.delete(LOG)
