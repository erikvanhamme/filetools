#!/usr/bin/ruby

require_relative 'filetools'

begin
	puts 'FileDB Remove tool v0.0.1'
	db = init_db

	removed = 0

	rows = db.execute('SELECT path FROM files')
	rows.each do |row|
		unless File.exist?(row[0])
			db.execute("DELETE FROM files WHERE path=\"#{row[0]}\"")
			removed += 1
		end
	end

	puts 'Report:'
	puts "  #{removed} files were removed from the database."
rescue SQLite3::Exception => e 
    puts "Exception occurred"
    puts e
ensure
    db.close if db
end
