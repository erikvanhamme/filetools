require 'sqlite3'

def init_db
    db = SQLite3::Database.new "filetools.db"
    puts 'SQLite db version:' + db.get_first_value('SELECT SQLITE_VERSION()')

    # TODO: Handle version checks/db updates properly.

    # Create files table.
	db.execute 'CREATE TABLE IF NOT EXISTS files(number INTEGER PRIMARY KEY, 
        sha1 INTEGER, size INTEGER, mtime INTEGER, path TEXT, latest INTEGER)'

	db.execute 'CREATE INDEX IF NOT EXISTS files_sha1 ON files(sha1)'
	db.execute 'CREATE INDEX IF NOT EXISTS files_path ON files(path)'

	puts db.get_first_value('SELECT COUNT(*) FROM files').to_s + ' files in database.'

    # Create tapes table.
    db.execute 'CREATE TABLE IF NOT EXISTS tapes(number INTEGER PRIMARY KEY,
        label TEXT, size INTEGER, tapeset INTEGER, tapeset_idx INTEGER)'

    puts db.get_first_value('SELECT COUNT(*) FROM tapes').to_s + ' tapes in database.'

    # Create tapeset table.
    db.execute 'CREATE TABLE IF NOT EXISTS tapesets(number INTEGER PRIMARY KEY,
        name TEXT, tape_count INTEGER)'

    puts db.get_first_value('SELECT COUNT(*) FROM tapesets').to_s + ' tape sets in database.'

    # Create files_tape link table.
    db.execute 'CREATE TABLE IF NOT EXISTS file_tape_links(file_number INTEGER, 
        tape_number INTEGER)'

    puts db.get_first_value('SELECT COUNT(*) FROM file_tape_links').to_s + ' file <-> tape links in database.'

	db
end

