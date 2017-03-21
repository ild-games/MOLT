#!/usr/local/bin/ruby

require 'json'
require 'getoptlong'
require 'set'

def config_is_valid?(verbose = false)
    begin
        config_hashs = JSON.parse(File.read('config.json'))
        config_formats_hash = JSON.parse(File.read('configformat.json'))
    rescue 
        puts 'Could not read config, please restore from default'
        return false
    end
    return configs_follow_format?(config_hashs, config_formats_hash, verbose)
end

def configs_follow_format?(config_hashs, config_formats_hash, verbose = false)
    valid = true
    config_formats_hash.keys.each do |config_name|
        verbose and puts("\n" + config_name + "\n--------------")
        if !config_hashs[config_name] || config_hashs[config_name] == ""
            verbose and puts(config_name + ' missing from config.json')
            valid = false
            next
        end
        if !value_matches_format?(config_hashs[config_name], config_formats_hash[config_name], verbose)
            valid = false
            next
        end
        verbose and puts("Is all good!")
    end
    return valid
end

def value_matches_format?(value, config_hash_format, verbose = false)
    if !value_matches_file_type?(value, config_hash_format['file_type'], verbose)
        return false
    end
    if !file_name_matches_extension(value, config_hash_format['extension'], verbose)
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
                            in molt.config; will check the configuration
                            file before running to ensure it is valid
        --checkConfig, -c   Validate the configuration file, does nothing if 
                            --run is already being used
        HELP_TEXT
        return
    end

    if !config_is_valid?(flags_set.include?('--verbose'))
        puts 'Configuration of molt is invalid'
        if !flags_set.include?('--verbose') then puts 'Use -v for more information' end
        return
    end

    if flags_set.include?('--run')
        puts "Running molt..." 
        render_using_config()
    end
end

def get_flags_set_from_arguments()
    opts = GetoptLong.new(
        [ '--help', '-h', GetoptLong::NO_ARGUMENT],
        [ '--verbose', '-v', GetoptLong::NO_ARGUMENT],
        [ '--run', '-r', GetoptLong::NO_ARGUMENT],
        [ '--checkConfig', '-c', GetoptLong::NO_ARGUMENT]
    )

    flags_set = Set.new
    opts.each do |opt, arg|
        flags_set.add(opt)
    end
    return flags_set
end

def render_using_config()
    config_hash = JSON.parse(File.read('config.json'))
    source_name = "OG"
    render_command = "aerender.exe -reuse"
    render_command << " -project \"#{config_hash['ae_project']}\""
    render_command << " -OMtemplate \"#{config_hash['ae_output_module']}\""
    render_command << " -comp \"#{config_hash['ae_comp_name']}\""
    render_command << " -output \"#{get_output_name(config_hash, source_name)}\""

    puts render_command
    system(render_command)
end

def get_output_name(config_hash, current_source_name)
    return config_hash['output_directory'] + config_hash['output_prefix'] + current_source_name
end

run_molt()