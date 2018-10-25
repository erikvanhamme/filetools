require_relative 'db'

class State
    attr_accessor :db, :version, :db_version, :tool, :verbose, :quiet, :argv, \
                    :incompatible, :files_added, :files_updated, :files_removed, \
                    :tapes_added

    def initialize(tool)
        @version = 1
        @db_version = 1
        @tool = tool
        @verbose = false
        @quiet = false
        @argv = []
        @incompatible = false
        @files_added = 0
        @files_updated = 0
        @files_removed = 0
        @tapes_added = 0
    end
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

    db_init
    db = $state.db
    
    if is_db_empty
        create_db_schema
    else
        check_db_schema
    end

    if $state.incompatible
        exit -1
    end

    unless $state.quiet
        puts '  ' + db.get_first_value('SELECT COUNT(*) FROM files').to_s + ' file records in database.'
        puts '  ' + db.get_first_value('SELECT COUNT(*) FROM tapes').to_s + ' tape records in database.'
        puts '  ' + db.get_first_value('SELECT COUNT(*) FROM tapesets').to_s + ' tape set records in database.'
        puts '  ' + db.get_first_value('SELECT COUNT(*) FROM file_tape_links').to_s + ' file <-> tape link records in database.'
    end
end

def report
    unless $state.quiet
        puts 'Report:'
        mods = 0
        if $state.files_added > 0
            puts "  #{$state.files_added} file records added."
            mods += $state.files_added
        end
        if $state.files_removed > 0
            puts "  #{$state.files_removed} file records removed."
            mods += $state.files_removed
        end
        if $state.files_updated > 0
            puts "  #{$state.files_updated} file records updated."
            mods += $state.files_updated
        end
        if $state.tapes_added > 0
            puts "  #{$state.tapes_added} tape records added."
            mods += $state.tapes_added
        end
        if mods == 0
            puts '  No database changes.'
        end
    end
end

