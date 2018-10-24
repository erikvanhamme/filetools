#!/usr/bin/ruby

require_relative 'filetools'

$state = State.new('template')

begin
	init
    db = $state.db

    report
rescue SQLite3::Exception => e 
    puts "Database exception occurred:"
    puts e
ensure
    db = $state.db
    db.close if db
end
