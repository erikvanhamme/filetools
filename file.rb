require 'digest/sha1'

def sha1_file(absolute_path)
    sha1 = Digest::SHA1.new()
    File.open(absolute_path, 'rb') do |iostream|
        while (block = iostream.read(4096)) && block.length > 0
            sha1.update(block)
        end
    end
    sha1.hexdigest
end

def valid_directory(directory)
    return File.directory?(directory)
end

def directory_args_valid
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

def file_exists(file)
    if $state.verbose
        puts "File record for #{file} exists."
    end
end

def file_doesnt_exist(file)
    unless $state.quiet
        puts "File record for #{file} does not exist."
    end
end

def file_added(file)
    $state.files_added += 1
    if $state.verbose
        puts "File record for #{file} added."
    end
end

def file_removed(file)
    $state.files_removed += 1
    if $state.verbose
        puts "File record for #{file} removed."
    end
end

def file_updated(file)
    $state.files_updated += 1
    if $state.verbose
        puts "File record for #{file} updated."
    end
end

