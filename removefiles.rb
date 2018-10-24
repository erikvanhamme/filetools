#!/usr/bin/ruby

require 'find'

require_relative 'filetools'

$state = State.new('remove files tool')

begin
	init
    db = $state.db

    if directory_args_valid
	    $state.argv.each do |dir|
		    Find.find(dir) do |path|
			    if File.file?(path)
				    absolute_path = File.expand_path(path)

                    files = db.execute("SELECT * FROM files WHERE path=\"#{absolute_path}\" AND latest=1 AND deleted=0")
                    if files.length == 0
                        file_doesnt_exist(absolute_path)
                    elsif files.length == 1
                        file = files[0]

                        file_num = file[0]
                        on_tapes = db.get_first_value("SELECT COUNT (*) FROM file_tape_links WHERE file_number=#{file_num}").to_i

                        if on_tapes != 0
                            db.execute("UPDATE files SET latest=0, deleted=1 WHERE number=#{file_num}")
                            file_updated(absolute_path)
                        else
                            db.execute("DELETE FROM files WHERE number=#{file_num}")
                            file_removed(absolute_path)
                        end
                    else
                        puts "Error: #{absolute_path} appears multiple times as latest file in database."
                    end
                end
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
