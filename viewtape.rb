#!/usr/bin/ruby

require_relative 'tape'
require_relative 'tool'

def tool_run(state, db)
    if tape_args_valid() && (state.argv.length() > 0)
        tape_label = state.argv[0]
        puts("Contents for tape #{tape_label}:")

        files = db.execute("SELECT path, sha1 FROM files LEFT JOIN file_tape_links ON file_tape_links.file_number = files.number LEFT JOIN tapes ON tapes.number = file_tape_links.tape_number WHERE tapes.label=\"#{tape_label}\"")

        files.each() do |file|
            puts("  #{file[1]} #{file[0]}")
        end
    end
end

tool_new('view tape tool')

