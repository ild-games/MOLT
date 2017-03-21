#!/usr/local/bin/ruby

require 'json'
require 'getoptlong'
require 'set'

def config_is_valid?(verbose = false)
    begin
        hash_configs = JSON.parse(File.read('config.json'))
        hash_config_formats = JSON.parse(File.read('configformat.json'))
    rescue 
        puts 'Could not read config, please restore from default'
        return false
    end
    return configs_follow_format?(hash_configs, hash_config_formats, verbose)
end

def configs_follow_format?(hash_configs, hash_config_formats, verbose = false)
    valid = true
    hash_config_formats.keys.each do |config_name|
        verbose and puts("\n" + config_name + "\n--------------")
        if !hash_configs[config_name] || hash_configs[config_name] == ""
            verbose and puts(config_name + ' missing from config.json')
            valid = false
            next
        end
        if !value_matches_format?(hash_configs[config_name], hash_config_formats[config_name], verbose)
            valid = false
            next
        end
        verbose and puts("Is all good!")
    end
    return valid
end

def value_matches_format?(value, hash_config_format, verbose = false)
    if !value_matches_file_type?(value, hash_config_format['file_type'], verbose)
        return false
    end
    if !file_name_matches_extension(value, hash_config_format['extension'], verbose)
        return false
    end
    return true
end

def value_matches_file_type?(value, file_type, verbose)
    if !file_type
        return true
    end
    
    if !File.exist?(value)
        verbose and puts(value + ' does not exist')
        return false
    end

    if File.ftype(value) != file_type
        verbose and puts(value + ' is not a ' + file_type)
        return false
    end

    return true
end

def file_name_matches_extension(value, extension, verbose)
    if !extension
        return true
    end

    if !File.fnmatch?(extension, File.basename(value))
        verbose and puts(value + ' is not of the type ' + extension)
        return false
    end

    if !File.exist?(value)
        verbose and puts('The file ' + value + ' does not exist.')
        return false
    end

    return true
end

def run_molt()
    flags_set = get_flags_set_from_arguments

    if flags_set.include?("--help") || flags_set.empty?() || (!flags_set.include?('--run') && !flags_set.include?('--checkConfig'))
        puts <<-HELP_TEXT
    MOLT
    --------------------------------
    usage: [--help] [--verbose] [--run] [--checkConfig]
    options:
        --help, -h          Show this screen
        --verbose, -v       Show additional output when running, 
                            can be used with --run or --checkConfig
        --run, -r           Run MOLT according to the configuration provided 
                            in molt.config; by default, will check the configuration
                            file before running to ensure it is valid
        --checkConfig, -c   Validate the configuration file, does nothing if 
                            --run is already being used
        --noCheck, -n       Skip validation of the configuration file

        HELP_TEXT
        return
    end

    if !flags_set.include?('--noCheck') && (flags_set.include?('--checkConfig') || flags_set.include?('--run'))
        if !config_is_valid?(flags_set.include?('--verbose'))
            puts 'Configuration of molt is invalid'
            if !flags_set.include?('--verbose') then puts 'Use -v for more information' end
            return
        end
    end

    if flags_set.include?('--run')
        puts "Running molt..." 
    end
end

def get_flags_set_from_arguments()
    opts = GetoptLong.new(
        [ '--help', '-h', GetoptLong::NO_ARGUMENT],
        [ '--verbose', '-v', GetoptLong::NO_ARGUMENT],
        [ '--run', '-r', GetoptLong::NO_ARGUMENT],
        [ '--checkConfig', '-c', GetoptLong::NO_ARGUMENT],    
        [ '--noCheck', '-n', GetoptLong::NO_ARGUMENT]
    )

    flags_set = Set.new
    opts.each do |opt, arg|
        flags_set.add(opt)
    end
    return flags_set
end


run_molt()