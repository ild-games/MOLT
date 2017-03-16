require 'json'

def config_is_valid?(verbose = false)
    begin
        hash_configs = JSON.parse(File.read('config.json'))
        hash_config_formats = JSON.parse(File.read('configformat.json'))
    rescue 
        puts 'Could not read config, please restore from default'
        return
    end
    configs_follow_format?(hash_configs, hash_config_formats, verbose)
end

def configs_follow_format?(hash_configs, hash_config_formats, verbose = false)
    valid = true
    hash_config_formats.keys.each do |config_name|
        verbose and puts("\n\n" + config_name + "\n--------------")
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
end

def value_matches_format?(value, hash_config_format, verbose = false)
    if !value_matches_file_type?(value, hash_config_format['file_type'], verbose)
        return false
    end
    if !value_matches_extension(value, hash_config_format['extension'], verbose)
        return false
    end
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

def value_matches_extension(value, extension, verbose)
    if !extension
        return true
    end

    if !File.fnmatch(extension, value)
        verbose and puts(value + ' is not of the type ' + extension)
        return false
    end

    return true
end

yeah = config_is_valid?(true)