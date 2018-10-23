#!/usr/bin/ruby

require_relative 'filetools'

$state = State.new('add tapes tool')

def args_valid
    # TODO: implement proper validation of command line arguments.
    true
end

def tape_size(label)
    size = 0
    suffix = label.split(//).last(2).join
    case suffix
    when 'l4'
        size = 800000000000
    end
    size
end

begin
	init
    db = $state.db

    added = 0

    if args_valid
        ARGV.each do |label|
            present_in_db = db.get_first_value("SELECT COUNT(*) FROM tapes WHERE label=\"#{label}\"").to_i
            if present_in_db == 0
                size = tape_size(label)

                db.execute("INSERT INTO tapes (label, size, tapeset, tapeset_idx) VALUES (\"#{label}\", #{size}, -1, -1)")

                added += 1
            else
                puts "Tape with label #{label} is already in the database."
            end
        end
    end

	puts 'Report:'
    puts "  #{added} tapes were added to the database."
rescue SQLite3::Exception => e 
    puts "Database exception occurred:"
    puts e
ensure
    db = $state.db
    db.close if db
end
