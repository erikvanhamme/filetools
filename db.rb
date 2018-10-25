require 'sqlite3'

def db_init
    $state.db = SQLite3::Database.new "filetools.db"
end

#db
def is_db_empty
    db = $state.db

    version_table = db.execute('SELECT name FROM sqlite_master WHERE type="table" AND name="version"')

    version_table.length == 0
end

#db
def create_version_table
    db = $state.db

    db.execute('CREATE TABLE version(version INTEGER NOT NULL, db_version INTEGER NOT NULL)')

    db.execute("INSERT INTO version(version, db_version) VALUES(#{$state.version}, #{$state.db_version})")
end

#db
def create_files_table
    db = $state.db
    
	db.execute 'CREATE TABLE IF NOT EXISTS files(number INTEGER PRIMARY KEY, 
        sha1 TEXT, size INTEGER, mtime INTEGER, path TEXT, latest INTEGER,
        deleted INTEGER)'

	db.execute 'CREATE INDEX IF NOT EXISTS files_sha1 ON files(sha1)'
	db.execute 'CREATE INDEX IF NOT EXISTS files_path ON files(path)'
end

#db
def create_tapes_table
    db = $state.db
    
    db.execute 'CREATE TABLE IF NOT EXISTS tapes(number INTEGER PRIMARY KEY,
        label TEXT, size INTEGER, tapeset INTEGER, tapeset_idx INTEGER)'
end

#db
def create_tapesets_table
    db = $state.db
    
    db.execute 'CREATE TABLE IF NOT EXISTS tapesets(number INTEGER PRIMARY KEY,
        name TEXT, tape_count INTEGER)'
end

#db
def create_file_tape_links_table
    db = $state.db
    
    db.execute 'CREATE TABLE IF NOT EXISTS file_tape_links(file_number INTEGER, 
        tape_number INTEGER)'
end

#db
def create_db_schema
    unless $state.quiet
        puts 'Initializing new database.'
    end
    create_version_table
    create_files_table
    create_tapes_table
    create_tapesets_table
    create_file_tape_links_table
end

#db
def increment_db_schema(current)
    db = $state.db

    unless $state.quiet
        puts "Updating database schema from V#{current}."
    end

    if current == 1
        # TODO: Handle schema update from V1 to V2 here.
    end
    if current == 2
        # TODO: Handle schema update from V2 to V3 here.
    end
    current += 1

    db.execute("UPDATE version SET db_version=#{current}")

    current
end

#db
def update_db_schema
    db = $state.db
    
    versions = db.execute('SELECT * FROM version')
    version_in_db = versions[0][0]
    db_version_in_db = versions[0][1]

    if version_in_db != $state.version
        db.execute("UPDATE version SET version=#{$state.version}")
    end

    while(db_version_in_db < $state.db_version)
        db_version_in_db = increment_db_schema(db_version_in_db)
    end
end

#db
def check_db_schema
    db = $state.db
    
    versions = db.execute('SELECT * FROM version')
    version_in_db = versions[0][0]
    db_version_in_db = versions[0][1]

    if (version_in_db > $state.version) || (db_version_in_db > $state.db_version)
        puts 'Error: Database was created with higher code or database version of the tools.'
        $state.incompatible = true
        return
    end
    
    update_db_schema
end

