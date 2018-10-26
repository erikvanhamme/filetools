#!/usr/bin/ruby

require_relative 'tape'
require_relative 'tool'

def tool_run(state, db)
    error = false

    # TODO: Handle command line arguments.

    accumulator = 0

    # TODO: Decide if First Fit Decreasing is a better algorithm to use then just First Fit.
    #       Make the DB sort Descending on size to switch.
    # files = db.execute('SELECT * FROM files ORDER BY size DESC')
    files = db.execute('SELECT * FROM files ORDER BY path ASC')
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

    unless error
        if state.verbose
            for i in 0..(tapes_needed - 1)
                bytes_on_tape = bytes_per_tape - tape_bytes_left[i]
                tape_use_percentage =  (bytes_on_tape.to_f / first_tape_size) * 100
                puts("Tape #{i} holds #{bytes_on_tape} bytes in #{tape_contents[i].length()} files and is used [#{tape_use_percentage}]%.")
                for j in 0..9
                    puts("  #{j}: #{tape_contents[i][j][4]}")
                end
            end
        end
    end
end

tool_new('add tape set tool')

