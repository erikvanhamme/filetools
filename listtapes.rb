#!/usr/bin/ruby

require_relative 'tape'
require_relative 'tool'

$state = State.new('list tapes tool')

begin
	init
    db = $state.db

    unless $state.quiet
        tapes = db.execute('SELECT * FROM tapes')
        puts "Number:\tLabel:\t\tTape size:\tTapeset:\tTapeset idx:"
        tapes.each do |tape|
            puts "#{tape[0]}\t#{tape[1]}\t#{tape[2]}\t#{tape[3]}\t\t#{tape[4]}"
        end
    end
rescue SQLite3::Exception => e 
    puts "Database exception occurred:"
    puts e
ensure
    db = $state.db
    db.close if db
end
