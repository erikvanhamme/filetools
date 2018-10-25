#!/usr/bin/ruby

require_relative 'tool'

def tool_run(state, db)
    unless state.quiet
        tapes = db.execute('SELECT * FROM tapes')
        puts("Number:\tLabel:\t\tTape size:\tTapeset:\tTapeset idx:")
        tapes.each() do |tape|
            puts("#{tape[0]}\t#{tape[1]}\t#{tape[2]}\t#{tape[3]}\t\t#{tape[4]}")
        end
    end
end

tool_new('list tapes tool', false)

