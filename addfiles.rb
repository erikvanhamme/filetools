#!/usr/bin/ruby

require 'find'

require_relative 'filetools'

$state = State.new('add files tool')

def args_valid
    valid = true
    $state.argv.each do |directory|
        directory_valid = valid_directory(directory)
        unless directory_valid
            puts "Invalid directory supplied on command line: #{directory}."
        end
        valid = directory_valid && valid
    end
    valid
end

begin
	init
    db = $state.db

    added = 0

    if args_valid
	    $state.argv.each do |dir|
		    Find.find(dir) do |path|
			    if File.file?(path)
				    absolute_path = File.expand_path(path)
				    filesize = File.size(absolute_path)
				    mtime = File.mtime(absolute_path)

                    present_in_db = db.get_first_value("SELECT COUNT(*) FROM files WHERE path=\"#{absolute_path}\" AND size=#{filesize} AND mtime=#{mtime.to_i}").to_i
                    if present_in_db == 0
    					sha1_num = sha1_file(absolute_path)
    
    					db.execute("INSERT INTO files (sha1, size, mtime, path, latest, deleted) VALUES (#{sha1_num.to_s}, #{filesize}, #{mtime.to_i}, \"#{absolute_path}\", 1, 0)")

                        if $state.verbose
                            puts "Added file #{absolute_path} to the database."
                        end

                        added += 1
                    end
                end
            end
        end
    end

    unless $state.quiet
    	puts 'Report:'
        puts "  #{added} files were added to the database."
    end
rescue SQLite3::Exception => e 
    puts "Database exception occurred:"
    puts e
ensure
    db = $state.db
    db.close if db
end
