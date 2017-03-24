require 'fileutils';

class Squid

  def initialize(logger, reload_cmd, conf_dir, pass_file)
    @logger = logger
    @squid_reload_command = reload_cmd
    @config_dir = conf_dir
    @htpasswd_file = pass_file
  end
  
  def reload_configuration(model)
    @logger.info("Updating squid config #{model}")
    write_squid_config(model)
    reload_squid
  end

  private

  def write_squid_config(model)
    
    File.open("#{@htpasswd_file}.new", 'w') do |file| 
      model.each_key do |username|
        file.write("#{username}:#{model[username]['htpasswd']}\n")
      end
    end
    
    FileUtils.mv "#{@htpasswd_file}.new", "#{@htpasswd_file}", :force => true
    
    File.open(File.join(@config_dir, 'users.conf'), 'w') do |file|
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
    
    Dir.exist?(File.join(@config_dir, 'groups')) and FileUtils.rm_r(File.join(@config_dir, 'groups'))
    Dir.exist?(File.join(@config_dir, 'sites')) and FileUtils.rm_r(File.join(@config_dir, 'sites'))
    FileUtils.mkdir_p(File.join(@config_dir, 'groups'))
    FileUtils.mkdir_p(File.join(@config_dir, 'sites'))
    
    model.each_key do |username|
      File.open(File.join(@config_dir, 'groups', "group_#{username}.txt"), "w") do |file|
        file.write("#{username}\n")
      end
      
      File.open(File.join(@config_dir, 'sites', "sites_#{username}.txt"), "w") do |file|
        model[username]['allow_rules'].each do |rule|
          file.write("#{rule}\n")
        end
      end      
    end
  end

  def execute_command(command)
    @logger.debug "Executing: #{command}"
    output = `#{command} 2>&1`
    @logger.debug "Result: #{$?}"
    @logger.debug "Output: #{output}"
    [$?, output]
  end

    
  def reload_squid
    execute_command(@squid_reload_command)
  end
  
  
end


