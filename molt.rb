#!/usr/local/bin/ruby

require 'json'
require 'getoptlong'
require 'set'
require 'fileutils'

def run_molt()
  flags_set = get_flags_set_from_arguments

  if flags_set.include?('--help') || flags_set.empty?() || (!flags_set.include?('--run') && !flags_set.include?('--checkConfig') && !flags_set.include?('--print'))
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
        --print, -p         Print the files to be created
        HELP_TEXT
    return
  end

  if !config_is_valid?(flags_set.include?('--verbose'))
    puts 'Configuration of molt is invalid'
    if !flags_set.include?('--verbose') then puts 'Use -v for more information' end
    return
  end

  if flags_set.include?('--run') or flags_set.include?('--print')
    puts "Running molt..."
    config_hash = JSON.parse(File.read('config.json'))
    missing_renders = get_missing_renders(config_hash)
    render_missing_renders(missing_renders, config_hash, flags_set.include?('--print'))
  end
end

def get_missing_renders(config_hash)
  missing_renders = {}

  Dir.glob(File.absolute_path(config_hash['source_directory']) + '/*.ai') do |current_source_path|
    source_name = get_source_name_from_path(current_source_path, config_hash)
    render_directory = File.absolute_path(config_hash['output_directory']) + '/' + source_name
    missing_comps_for_source = []

    config_hash['comps_to_render'].each do |comp|
      if Dir.glob(render_directory + '/*' + comp['output_prefix'] + '*').length == 0
        missing_comps_for_source.push(comp)
      end
    end

    if missing_comps_for_source.length != 0
      missing_renders[current_source_path] = missing_comps_for_source
    end
  end

  return missing_renders
end

def config_is_valid?(verbose = false)
  begin
    config_hash = JSON.parse(File.read('config.json'))
  rescue
    puts 'Config file could not be parsed or could not be opened'
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
    ['--help', '-h', GetoptLong::NO_ARGUMENT],
    ['--verbose', '-v', GetoptLong::NO_ARGUMENT],
    ['--run', '-r', GetoptLong::NO_ARGUMENT],
    ['--checkConfig', '-c', GetoptLong::NO_ARGUMENT],
    ['--print', '-p', GetoptLong::NO_ARGUMENT]
  )

  flags_set = Set.new
  opts.each do |opt, arg|
    flags_set.add(opt)
  end
  return flags_set
end

$TEMP_WORKING_AI_FILE_NAME = "E5J0OsuPX4.ai"

def render_missing_renders(missing_renders, config_hash, print_commands_only)
  cache_off_working_ai_file_from_config(config_hash)
  missing_renders.each do |source_path, missing_comps|
    set_source_as_working_file(source_path, config_hash)
    dir_name = config_hash['output_directory'] + '/' + get_source_name_from_path(source_path, config_hash)
    FileUtils.mkdir_p(dir_name) unless Dir.exist?(dir_name)

    missing_comps.each do |comp|
      render_command = get_render_command(config_hash, source_path, comp["name"], comp["output_prefix"])
      if print_commands_only
        puts render_command
        puts "\n"
        next
      end
      output = `#{render_command}`
    end
    set_working_file_back_to_source(source_path, config_hash)
  end
  restore_working_ai_file_from_config(config_hash)
end

def set_source_as_working_file(source_path, config_hash)
  if (File.basename(source_path) == File.basename(config_hash['working_ai_file']))
    source_path = File.dirname(source_path) + '/' + $TEMP_WORKING_AI_FILE_NAME
  end
  File.rename(File.absolute_path(source_path),
              File.absolute_path(config_hash['working_ai_file']))
end

def set_working_file_back_to_source(source_path, config_hash)
  if (File.basename(source_path) == File.basename(config_hash['working_ai_file']))
    source_path = File.dirname(source_path) + '/' + $TEMP_WORKING_AI_FILE_NAME
  end
  File.rename(File.absolute_path(config_hash['working_ai_file']),
              File.absolute_path(source_path))
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
