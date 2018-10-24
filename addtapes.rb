#!/usr/bin/ruby

require_relative 'filetools'

$state = State.new('add tapes tool')

def args_valid
    valid = true
    $state.argv.each do |label|
        label_valid = valid_tape_label(label)
        unless label_valid
            puts "Invalid label supplied on command line: #{label}."
        end
        valid = label_valid && valid
    end
    valid
end

def tape_size(label)
    size = 0
    suffix = label.split(//).last(2).join
    case suffix
    when 'L4'
        size = 800000000000
    end
    size
end

begin
	init
    db = $state.db

    added = 0

    if args_valid
        $state.argv.each do |label|
            present_in_db = db.get_first_value("SELECT COUNT(*) FROM tapes WHERE label=\"#{label}\"").to_i
            if present_in_db == 0
                size = tape_size(label)

                db.execute("INSERT INTO tapes (label, size, tapeset, tapeset_idx) VALUES (\"#{label}\", #{size}, -1, -1)")

                if $state.verbose
                    puts "Adding tape with label #{label} to the database."
                end

                added += 1
            else
                puts "Tape with label #{label} is already in the database."
            end
        end
    end

    unless $state.quiet
        puts 'Report:'
        puts "  #{added} tapes were added to the database."
    end
rescue SQLite3::Exception => e 
    puts "Database exception occurred:"
    puts e
ensure
    db = $state.db
    db.close if db
end
