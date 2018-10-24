#!/usr/bin/ruby

require 'find'

require_relative 'filetools'

$state = State.new('add files tool')

begin
	init
    db = $state.db

    if directory_args_valid
	    $state.argv.each do |dir|
		    Find.find(dir) do |path|
			    if File.file?(path)
				    absolute_path = File.expand_path(path)
				    filesize = File.size(absolute_path)
				    mtime = File.mtime(absolute_path)

                    present_in_db = db.get_first_value("SELECT COUNT(*) FROM files WHERE path=\"#{absolute_path}\" AND deleted=0").to_i
                    if present_in_db == 0
                        sha1 = sha1_file(absolute_path)
                        db.execute("INSERT INTO files (sha1, size, mtime, path, latest, deleted) VALUES (\"#{sha1}\", #{filesize}, #{mtime.to_i}, \"#{absolute_path}\", 1, 0)")
                        file_added(absolute_path)
                    else
                        file_exists(absolute_path)
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
