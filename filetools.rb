require 'digest/sha1'
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

class State
    attr_accessor :db, :version, :db_version, :tool, :verbose, :quiet, :argv, :incompatible

    def initialize(tool)
        @version = 1
        @db_version = 1
        @tool = tool
        @verbose = false
        @quiet = false
        @argv = []
        @incompatible = false
    end
end

def is_db_empty
    db = $state.db

    version_table = db.execute('SELECT name FROM sqlite_master WHERE type="table" AND name="version"')

    version_table.length == 0
end

def create_version_table
    db = $state.db

    db.execute('CREATE TABLE version(version INTEGER NOT NULL, db_version INTEGER NOT NULL)')

    db.execute("INSERT INTO version(version, db_version) VALUES(#{$state.version}, #{$state.db_version})")
end

def create_files_table
    db = $state.db
    
	db.execute 'CREATE TABLE IF NOT EXISTS files(number INTEGER PRIMARY KEY, 
        sha1 INTEGER, size INTEGER, mtime INTEGER, path TEXT, latest INTEGER,
        deleted INTEGER)'

	db.execute 'CREATE INDEX IF NOT EXISTS files_sha1 ON files(sha1)'
	db.execute 'CREATE INDEX IF NOT EXISTS files_path ON files(path)'
end

def create_tapes_table
    db = $state.db
    
    db.execute 'CREATE TABLE IF NOT EXISTS tapes(number INTEGER PRIMARY KEY,
        label TEXT, size INTEGER, tapeset INTEGER, tapeset_idx INTEGER)'
end

def create_tapesets_table
    db = $state.db
    
    db.execute 'CREATE TABLE IF NOT EXISTS tapesets(number INTEGER PRIMARY KEY,
        name TEXT, tape_count INTEGER)'
end

def create_file_tape_links_table
    db = $state.db
    
    db.execute 'CREATE TABLE IF NOT EXISTS file_tape_links(file_number INTEGER, 
        tape_number INTEGER)'
end

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

def scan_args
    ARGV.each do |arg|
        case arg
        when '-v'
            $state.verbose = true
        when '-q'
            $state.quiet = true
        else
            $state.argv << arg
        end
        if $state.quiet
            $state.verbose = false
        end
    end
end

def init
    scan_args

    unless $state.quiet
        puts "FileTools: #{$state.tool} (code version: #{$state.version} using db_version: #{$state.db_version})"
    end
    db = SQLite3::Database.new "filetools.db"
    $state.db = db
    
    if is_db_empty
        create_db_schema
    else
        check_db_schema
    end

    if $state.incompatible
        exit -1
    end

    unless $state.quiet
        puts '  ' + db.get_first_value('SELECT COUNT(*) FROM files').to_s + ' files in database.'
        puts '  ' + db.get_first_value('SELECT COUNT(*) FROM tapes').to_s + ' tapes in database.'
        puts '  ' + db.get_first_value('SELECT COUNT(*) FROM tapesets').to_s + ' tape sets in database.'
        puts '  ' + db.get_first_value('SELECT COUNT(*) FROM file_tape_links').to_s + ' file <-> tape links in database.'
    end
end

def sha1_file(absolute_path)
    sha1 = Digest::SHA1.new()
    File.open(absolute_path, 'rb') do |iostream|
        while (block = iostream.read(4096)) && block.length > 0
            sha1.update(block)
        end
    end
    sha1.hexdigest.to_i(16)
end

def valid_tape_label(label)
    if label.length != 8
        return false
    end

    # Taken LTO tape label spec from:
    # https://www.ibm.com/support/knowledgecenter/en/STCMML8/com.ibm.storage.ts3500.doc/ipg_3584_mehlab.html
    # Only supporting LTO1-LTO8 for now.
    return label =~ /[A-Z0-9]{6}[L]{1}[1-8]{1}/
end

def valid_directory(directory)
    return File.directory?(directory)
end
















