#!/usr/local/bin/ruby

require 'json'
require 'getoptlong'
require 'set'
require 'fileutils'

def run_molt()
    flags_set = get_flags_set_from_arguments

    if flags_set.include?('--help') || flags_set.empty?() || (!flags_set.include?('--run') && !flags_set.include?('--checkConfig'))
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
        --removeTrailing
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

def config_is_valid?(verbose = false)
    begin
        config_hash = JSON.parse(File.read('config.json'))
    rescue 
        puts 'Could not read config, please restore from default'
        return false
    end

    return configs_follow_format?(config_hash, verbose)
end

def configs_follow_format?(config_hash, verbose = false)
    valid = true

    verbose and puts "\nae_project\n--------------"
    if !file_name_matches_extension?(config_hash['ae_project'], "*.aep", verbose) then valid = false end

    verbose and puts "\nsource_directory\n--------------"
    if !is_valid_directory?(config_hash['source_directory'], verbose) then valid = false end

    verbose and puts "\nworking_ai_file\n--------------"
    if !file_name_matches_extension?(config_hash['working_ai_file'], "*.ai", verbose) then valid = false end

    verbose and puts "\noutput_directory\n--------------"
    if !is_valid_directory?(config_hash['output_directory'], verbose) then valid = false end

    return valid
end

def is_valid_directory?(directory, verbose)
    if !File.exist?(directory)
        verbose and puts('"' + directory + '" does not exist')
        return false
    end

    if File.ftype(directory) != 'directory'
        verbose and puts('"' + directory + '" is not a directory')
        return false
    end

    return true
end

def file_name_matches_extension?(file_name, extension, verbose)
    if !extension
        return true
    end

    if !File.fnmatch?(extension, File.basename(file_name))
        verbose and puts(file_name + ' is not of the type ' + extension)
        return false
    end

    if !File.exist?(file_name)
        verbose and puts('The file ' + file_name + ' does not exist.')
        return false
    end

    return true
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

$TEMP_WORKING_AI_FILE_NAME = "E5J0OsuPX4.ai"

def render_using_config()
    config_hash = JSON.parse(File.read('config.json'))

    cache_off_working_ai_file_from_config(config_hash)
    Dir.glob(File.absolute_path(config_hash['source_directory']) + '/*.ai') do |current_source_path|
        File.rename(File.absolute_path(current_source_path),
            File.absolute_path(config_hash['working_ai_file']) )
       
        dir_name = config_hash['output_directory'] + '/' + get_source_name_from_path(current_source_path, config_hash)
        if (File.exists?(dir_name) || dir_name == $TEMP_WORKING_AI_FILE_NAME) 
            File.rename(File.absolute_path(config_hash['working_ai_file']),
                File.absolute_path(current_source_path))
            next
        end
        create_directory(dir_name)

        render_each_comp(config_hash, current_source_path)
        
        File.rename(File.absolute_path(config_hash['working_ai_file']),
                    File.absolute_path(current_source_path))
    end
    restore_working_ai_file_from_config(config_hash)
end

def create_directory(dir_name) 
    FileUtils.mkdir_p(dir_name) unless File.exist?(dir_name)
end

def render_each_comp(config_hash, current_source_path)
    comps_array = config_hash['comps_to_render']
    comps_array.each do |current_comp|
        if File.exist?(get_output_name(config_hash, current_source_path, current_comp["output_prefix"])) then next end
        render_command = get_render_command(config_hash, current_source_path, current_comp["name"], current_comp["output_prefix"] )
        output = `#{render_command}`
    end
end

def cache_off_working_ai_file_from_config(config_hash)
    File.rename(File.absolute_path(config_hash['working_ai_file']), 
                File.absolute_path(config_hash['source_directory']) + '/' + $TEMP_WORKING_AI_FILE_NAME)
end

def restore_working_ai_file_from_config(config_hash)
    File.rename(File.absolute_path(config_hash['source_directory']) + '/' + $TEMP_WORKING_AI_FILE_NAME,
                File.absolute_path(config_hash['working_ai_file']))
end

def get_render_command(config_hash, current_source_path, current_comp, output_prefix)
    render_command = "aerender.exe -reuse"
    render_command << " -project \"#{File.absolute_path(config_hash['ae_project'])}\""
    render_command << " -OMtemplate \"#{config_hash['ae_output_module']}\""
    render_command << " -comp \"#{current_comp}\""
    render_command << " -output \"#{get_output_name(config_hash, current_source_path, output_prefix)}\""
end

def get_output_name(config_hash, current_source_path, output_prefix)
    current_source_name = get_source_name_from_path(current_source_path, config_hash)
    return File.absolute_path(config_hash['output_directory']) + '/' + current_source_name +
            '/' + output_prefix + '[#]'
end

def get_source_name_from_path(source_path, config_hash) 
    source_name = File.basename(source_path, ".ai")
    if source_name == File.basename($TEMP_WORKING_AI_FILE_NAME, ".ai")
        source_name = File.basename(config_hash['working_ai_file'], ".ai")
    end
    return source_name
end

run_molt()