#!/usr/bin/ruby

require 'find'

require_relative 'filetools'

$state = State.new('update files tool')

begin
	init
    db = $state.db

    updated = 0
    added = 0

    if directory_args_valid
	    $state.argv.each do |dir|
		    Find.find(dir) do |path|
			    if File.file?(path)
				    absolute_path = File.expand_path(path)
				    filesize = File.size(absolute_path)
				    mtime = File.mtime(absolute_path)

                    files = db.execute("SELECT * FROM files WHERE path=\"#{absolute_path}\" AND latest=1 AND deleted=0")
                    if files.length == 0
                        msg_file_doesnt_exist(absolute_path)
                    elsif files.length == 1
                        file = files[0]

                        unless (file[2] == filesize) && (file[3] == mtime.to_i)
                            sha1 = sha1_file(absolute_path)
                            file_num = file[0]
                            on_tapes = db.get_first_value("SELECT COUNT (*) FROM file_tape_links WHERE file_number=#{file_num}").to_i

                            if on_tapes != 0
                                db.execute("UPDATE files SET latest=0 WHERE number=#{file_num}")
                                db.execute("INSERT INTO files (sha1, size, mtime, path, latest, deleted) VALUES (\"#{sha1}\", #{filesize}, #{mtime.to_i}, \"#{absolute_path}\", 1, 0)")
                                msg_file_added(absolute_path)
                                added += 1
                            else
                                db.execute("UPDATE files SET sha1=\"#{sha1}\", size=#{filesize}, mtime=#{mtime.to_i} WHERE number=#{file_num}")
                                msg_file_updated(absolute_path)
                                updated += 1
                            end
                        end
                    else
                        puts "Error: #{absolute_path} appears multiple times as latest file in database."
                    end
                end
            end
        end
    end

    unless $state.quiet
    	puts 'Report:'
        puts "  #{added} file records were added to the database."
        puts "  #{updated} file records were updated in the database."
    end
rescue SQLite3::Exception => e 
    puts "Database exception occurred:"
    puts e
ensure
    db = $state.db
    db.close if db
end
