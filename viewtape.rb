#!/usr/bin/ruby

require 'pathname'

require_relative 'tape'
require_relative 'tool'

def tool_run(state, db)
    relative = false

    argv = []
    state.argv.each() do |arg|
        if (arg == '-relative')
            relative = true
        else
            argv << arg
        end
    end

    if tape_args_valid(argv) && (argv.length() > 0)
        tape_label = state.argv[0]
        unless state.quiet
            puts("Contents for tape #{tape_label}:")
        end

        files = db.execute("SELECT path, sha1 FROM files LEFT JOIN file_tape_links ON file_tape_links.file_number = files.number LEFT JOIN tapes ON tapes.number = file_tape_links.tape_number WHERE tapes.label=\"#{tape_label}\" ORDER BY files.path ASC")

        files.each() do |file|
            if relative
                filename = Pathname.new(file[0]).relative_path_from(Pathname.new(File.expand_path(File.dirname(__FILE__)))).to_s
                puts("#{file[1]}  #{filename}")
            else
                puts("  #{file[1]} #{file[0]}")
            end
        end
    end
end

tool_new('view tape tool', false)

