#!/usr/bin/env ruby

require 'rubygems'

require_relative '../lib/parameters'

puts Parameters.new(input: $stdin.readlines, action: ARGV[0], stack_name: ARGV[1])
