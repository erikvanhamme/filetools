#!/usr/bin/ruby

require_relative 'tape'
require_relative 'tool'

$state = State.new('add tapes tool')

begin
	init
    db = $state.db

    if tape_args_valid
        $state.argv.each do |label|
            present_in_db = db.get_first_value("SELECT COUNT(*) FROM tapes WHERE label=\"#{label}\"").to_i
            if present_in_db == 0
                size = tape_size(label)
                db.execute("INSERT INTO tapes (label, size, tapeset, tapeset_idx) VALUES (\"#{label}\", #{size}, -1, -1)")
                tape_added(label)
            else
                tape_exists(label)
            end
        end
    end

    report
rescue SQLite3::Exception => e 
    puts "Database exception occurred:"
    puts e
ensure
    db = $state.db
    db.close if db
end
