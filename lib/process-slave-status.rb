#!/usr/bin/env ruby

require 'rubygems'

require_relative '../lib/slave_status'

puts SlaveStatus.new($stdin.readlines)
