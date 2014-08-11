require 'fileutils';

class Squid
  def initialize(logger)
    @logger = logger
    @squid_reload_command = $app_settings['squid']['reload_command']
    @config_dir = $app_settings['squid']['config_dir']
    @htpasswd_file = $app_settings['squid']['htpasswd_file']
  end
  
  def get_module_name
    "squid"
  end
  
  def reload_module(model)
    @logger.info("Updating squid config #{model}")
    write_squid_config(model)
    reload_squid
  end
  
  def write_squid_config(model)
    
    File.open(@htpasswd_file, 'w') do |file| 
      model.each_key do |username|
        file.write("#{username}:#{model[username]['htpasswd']}\n")
      end
    end
    
    File.open(File.join(@config_dir, "users.conf"), 'w') do |file| 
      model.each_key do |username|
        file.write("acl U#{username} proxy_auth \"#{@config_dir}/groups/group_#{username}.txt\"\n")
        file.write("acl S#{username} dstdomain \"#{@config_dir}/sites/sites_#{username}.txt\"\n")
      end
      
      file.write("\n")
      
      model.each_key do |username|
        file.write("http_access allow http port_80 S#{username} U#{username}\n")
        file.write("http_access allow https port_443 S#{username} U#{username}\n")
        file.write("http_access allow CONNECT S#{username} U#{username}\n")
      end
      
    end
    
    Dir.exists?(File.join(@config_dir, "groups")) and FileUtils.rm_r(File.join(@config_dir, "groups"))
    Dir.exists?(File.join(@config_dir, "sites")) and FileUtils.rm_r(File.join(@config_dir, "sites"))
    FileUtils.mkdir_p(File.join(@config_dir, "groups"))
    FileUtils.mkdir_p(File.join(@config_dir, "sites"))
    
    model.each_key do |username|
      File.open(File.join(@config_dir, "groups", "group_#{username}.txt"), "w") do |file|
        file.write("#{username}\n")
      end
      
      File.open(File.join(@config_dir, "sites", "sites_#{username}.txt"), "w") do |file|
        model[username]['allow_rules'].each do |rule|
          file.write("#{rule}\n")
        end
      end      
    end
  end
  
  def reload_squid
    
    @logger.debug "Executing: #{@squid_reload_command}"
    output = `#{@squid_reload_command} 2>&1`
    @logger.debug "Result: #{$?}"
    @logger.debug "Output: #{output}"
  end
  
end

$agent.register_module(Squid.new($logger))
