#!/usr/bin/ruby

require 'digest/sha1'
require 'find'

require_relative 'filetools'

def validate_args(args)
	#TODO: implement validation.
	args
end

def hash_path(absolute_path)
    sha1 = Digest::SHA1.new()
    File.open(absolute_path, 'rb') do |iostream|
        while (block = iostream.read(4096)) && block.length > 0
            sha1.update(block)
        end
    end
    sha1.hexdigest.to_i(16)
end

dirs = validate_args(ARGV)

begin
	puts 'FileDB Add/Update tool v0.0.1'
	db = init_db

	added = 0
	updated = 0

	dirs.each do |dir|
		Find.find(dir) do |path|
			if File.file?(path)
				absolute_path = File.expand_path(path)
				filesize = File.size(absolute_path)
				mtime = File.mtime(absolute_path)
				
				present_in_db = db.get_first_value("SELECT COUNT(*) FROM files WHERE path=\"#{absolute_path}\"").to_i
				if present_in_db == 0
					sha1_num = hash_path(absolute_path)
					
					db.execute("INSERT INTO files (sha1, size, mtime, path, latest) VALUES (#{sha1_num.to_s}, #{filesize}, #{mtime.to_i}, \"#{absolute_path}\", 1)")

					added += 1
				else
					db_mtime = Time.at(db.get_first_value("SELECT mtime FROM files WHERE path=\"#{absolute_path}\""))

					unless mtime.to_i == db_mtime.to_i
						sha1_num = hash_path(absolute_path)

						db.execute("UPDATE files SET sha1=#{sha1_num.to_s}, size=#{filesize}, mtime=#{mtime.to_i} WHERE path=\"#{absolute_path}\"")

						updated += 1
					end
				end
			end
		end
	end

	puts 'Report:'
	puts "  #{added} files were added to the database."
	puts "  #{updated} files were updated in the database."
rescue SQLite3::Exception => e 
    puts "Exception occurred"
    puts e
ensure
    db.close if db
end
