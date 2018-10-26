def valid_tape_label(label)
    if label.length != 8
        return false
    end

    # Taken LTO tape label spec from:
    # https://www.ibm.com/support/knowledgecenter/en/STCMML8/com.ibm.storage.ts3500.doc/ipg_3584_mehlab.html
    # Only supporting LTO1-LTO8 for now.
    return label =~ /[A-Z0-9]{6}[L]{1}[1-8]{1}/
end

def tape_args_valid
    valid = true
    $state.argv.each do |label|
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

def tape_added(label)
    $state.tapes_added += 1
    if $state.verbose
        puts "Tape record for #{label} added."
    end
end

