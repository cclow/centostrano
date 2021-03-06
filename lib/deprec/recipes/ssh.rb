# Copyright 2006-2008 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :centos do
    namespace :ssh do
      
      SYSTEM_CONFIG_FILES[:ssh] = [
        
        {:template => "sshd_config.erb",
         :path => '/etc/ssh/sshd_config',
         :mode => 0644,
         :owner => 'root:root'},
         
        {:template => "ssh_config.erb",
         :path => '/etc/ssh/ssh_config',
         :mode => 0644,
         :owner => 'root:root'}
      ]
      
      task :config_gen do        
        SYSTEM_CONFIG_FILES[:ssh].each do |file|
          deprec2.render_template(:ssh, file)
        end
        auth_keys_dir = 'config/ssh/authorized_keys'
        if ! File.directory?(auth_keys_dir)
          puts "Creating #{auth_keys_dir}"
          Dir.mkdir(auth_keys_dir)
        end
      end
      
      desc "Push ssh config files to server"
      task :config do
        deprec2.push_configs(:ssh, SYSTEM_CONFIG_FILES[:ssh])
        restart
      end

      desc "Start ssh"
      task :start do
        send(run_method, "/etc/init.d/sshd reload")
      end
    
      desc "Stop ssh"
      task :stop do
        send(run_method, "/etc/init.d/sshd reload")
      end
    
      desc "Restart ssh"
      task :restart do
        send(run_method, "/etc/init.d/sshd restart")
      end
    
      desc "Reload ssh"
      task :reload do
        send(run_method, "/etc/init.d/sshd reload")
      end
      
      desc "Sets up authorized_keys file on remote server"
      task :setup_keys do
        
        default(:target_user) { 
          Capistrano::CLI.ui.ask "Setup keys for which user?" do |q|
            q.default = user
          end
        }
        
        if target_user == user
          
          unless ssh_options[:keys]  
            puts <<-ERROR

            You need to define the name of your SSH key(s)
            e.g. ssh_options[:keys] = %w(/Users/your_username/.ssh/id_rsa)

            You can put this in your .caprc file in your home directory.

            ERROR
            exit
          end
        
          deprec2.mkdir '.ssh', :mode => 0700
          put(ssh_options[:keys].collect{|key| File.read(key+'.pub')}.join("\n"), '.ssh/authorized_keys', :mode => 0600 )
          
        else  
          
          deprec2.mkdir "/home/#{target_user}/.ssh", :mode => 0700, :owner => "#{target_user}.users", :via => :sudo
          std.su_put File.read("config/ssh/authorized_keys/#{target_user}"), "/home/#{target_user}/.ssh/authorized_keys", '/tmp/', :mode => 0600
          sudo "chown #{target_user}.users /home/#{target_user}/.ssh/authorized_keys"
          
        end
      end
      
    end
  end
end
