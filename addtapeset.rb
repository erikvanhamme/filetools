#!/usr/bin/ruby

require_relative 'file'
require_relative 'tape'
require_relative 'tool'

def tool_run(state, db)
    error = false
    files = nil
    no_filter = true
    first_fit_decreasing = false
    set_count = 1
    next_is_name = false
    tapeset_names = []
    
    # Handle command line arguments.
    argv = []
    state.argv.each() do |arg|
        case arg
        when '-ffd'
            first_fit_decreasing = true
        when '-double'
            set_count = [set_count, 2].max()
        when '-triple'
            set_count = [set_count, 3].max()
        when '-name'
            next_is_name = true
        else
            if (next_is_name)
                tapeset_names << arg
                next_is_name = false
            else
                argv << arg
                no_filter = false
            end
        end
    end
    if tapeset_names.length() == 0
        tapeset_names << 'tapeset'
    end
    if set_count > 1
        n = tapeset_names[0]
        tapeset_names = []
        for i in 0..(set_count - 1)
            suffix = ''
            case i
            when 0
                suffix = ' (primary)'
            when 1
                suffix = ' (secondary)'
            when 2
                suffix = ' (tertiary)'
            end
            tapeset_names << (n + suffix)
        end
    end
    tapeset_names.each do |n|
        # Check if the name already exists in the tapesets table.
        c = db.get_first_value("SELECT COUNT (*) FROM tapesets WHERE name=\"#{n}\"").to_i
        if (c > 0)
            tapeset_exists(n, true)
            error = true
        end
    end
    unless directory_args_valid(argv)
        #error = true
    end

    # Command line args alright? -> Proceed file selection from database.
    unless error
        accumulator = 0

        # Build the selection query.
        query = 'SELECT * FROM files'
        first = true
        unless no_filter
            query += ' WHERE'
            argv.each() do |arg|
                if(first)
                    query += " path LIKE \"#{arg}%\""
                    first = false
                else
                    query += " OR path LIKE \"#{arg}%\""
                end
            end
        end
        if (first_fit_decreasing)
            query += ' ORDER BY size DESC'
        else
            query += ' ORDER BY path ASC'
        end

        files = db.execute(query)
        if files.length() == 0
            puts("Error: No files matched the selection criteria.")
            error = true
        end
    end

    # File selection alright? -> Proceed to bin packing of the tapes.
    unless error
        files.each() do |file|
            accumulator += file[2]
        end
        average_size = accumulator / files.length()

        # TODO: This is bad, find a way to deal with tapes of different sizes.
        first_tape_size = db.get_first_value('SELECT size FROM tapes')

        # Reduce tape size with 5% to make room for TAR blocking overhead.
        first_tape_size = (0.95 * first_tape_size).to_i()

        # Get smallest integer number of tapes that will fit the data.
        tapes_needed = (accumulator.to_f() / first_tape_size).ceil()

        # Add the average file size here to give the bin packing algorithm some wriggle room.
        bytes_per_tape = (accumulator / tapes_needed) + average_size

        # Prepare.
        tape_contents = []
        tape_bytes_left = []
        for i in 0..(tapes_needed - 1)
            tape_contents[i] = []
            tape_bytes_left[i] = bytes_per_tape
        end

        # Bin packing of files. Using First Fit Decreasing algorithm.
        file_count = files.length()
        for i in 0..(file_count - 1)
            file_size = files[i][2]
            tape = 0
            stored = false
            for j in 0..(tapes_needed - 1)
                if (tape_bytes_left[j] > file_size)
                    tape_contents[j] << files[i]
                    tape_bytes_left[j] -= file_size
                    stored = true
                    break
                end
            end
            unless stored
                puts("Error: Failed to store file idx(#{i}). All tapes are full.")
                error = true
            end
        end
    end

    # Bin packing done? -> Proceed to database updates.
    unless error
        if state.verbose
            for i in 0..(tapes_needed - 1)
                bytes_on_tape = bytes_per_tape - tape_bytes_left[i]
                tape_use_percentage =  (bytes_on_tape.to_f / first_tape_size) * 100
                puts("Tape #{i} holds #{bytes_on_tape} bytes in #{tape_contents[i].length()} files and is used [#{tape_use_percentage.round(2)}]%.")
                limit = [tape_contents[i].length() - 1, 9].min()
                for j in 0..limit
                    puts("  #{j}: #{tape_contents[i][j][4]}")
                end
                tape_contents[i].each() do |file|
                    if file == nil
                        puts "nil!"
                    end
                end
            end

            puts tapeset_names
        end
    end
end

tool_new('add tape set tool')

