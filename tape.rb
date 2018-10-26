def valid_tape_label(label)
    if label.length != 8
        return false
    end

    # Taken LTO tape label spec from:
    # https://www.ibm.com/support/knowledgecenter/en/STCMML8/com.ibm.storage.ts3500.doc/ipg_3584_mehlab.html
    # Only supporting LTO1-LTO8 for now.
    return label =~ /[A-Z0-9]{6}[L]{1}[1-8]{1}/
end

def tape_args_valid(argv = $state.argv)
    valid = true
    argv.each do |label|
        label_valid = valid_tape_label(label)
        unless label_valid
            puts "Error: Invalid label supplied on command line: #{label}."
        end
        valid = label_valid && valid
    end
    valid
end

def tape_size(label)
    size = 0
    suffix = label.split(//).last(2).join
    case suffix
    when 'L4'
        size = 800000000000
    end
    size
end

def tape_exists(label)
    if $state.verbose
        puts "Tape record for #{label} exists."
    end
end

def tape_doesnt_exist(label)
    unless $state.quiet
        puts "Tape record for #{label} does not exist."
    end
end

def tape_added(label)
    $state.tapes_added += 1
    if $state.verbose
        puts "Tape record for #{label} added."
    end
end

def tape_updated(label)
    $state.tapes_updated += 1
    if $state.verbose
        puts "Tape record for #{label} updated."
    end
end

def tapeset_added(name)
    $state.tapesets_added += 1
    if $state.verbose
        puts "Tapeset record for #{name} added."
    end
end

def file_tape_link_added(name, label)
    $state.file_tape_links_added += 1
    if $state.verbose
        puts "File <-> tape link record for #{name}, #{label} added."
    end
end

def tapeset_exists(name, error=false)
    if ($state.verbose) || error
        e = ''
        if error
            e = 'Error: '
        end
        puts "#{e}Tapeset record for  #{name} exists." 
    end
end

