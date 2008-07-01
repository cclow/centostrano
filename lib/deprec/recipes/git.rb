# Copyright 2006-2008 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do 
    namespace :git do

      set :git_user, 'git'
      set :git_group, 'git'
      set :git_keys_file, '/home/git/.ssh/authorized_keys'
      set :git_root, '/var/git'

=begin
      SRC_PACKAGES[:git] = {
        :filename => 'git-1.5.5.4.tar.gz',   
        :md5sum => "8255894042c8a6db07227475b8b4622f  git-1.5.5.4.tar.gz", 
        :dir => 'git-1.5.5.4',  
        :url => "http://kernel.org/pub/software/scm/git/git-1.5.5.4.tar.gz",
        :unpack => "tar zxf git-1.5.5.4.tar.gz;",
        :configure => %w(
        ./configure
        ;
        ).reject{|arg| arg.match '#'}.join(' '),
        :make => 'make;',
        :install => 'make install;'
      }
=end

      desc "Install git"
      task :install do
        install_deps
      end

      # install dependencies for git
      task :install_deps do
        yum.enable_repository :epel
        apt.install( {:base => %w(git)}, :stable)
      end

      # Everything below is not tested on CentOS
      # I recommend to use Gitosis, couse it supports permissions
      
      desc "Grant user ssh access to git"
      task :add_user do
        default(:target_user) { 
          Capistrano::CLI.ui.ask "Add git keys for which user?" do |q|
            q.default = user
          end
        }
        if target_user == user
          unless ssh_options[:keys]  
            puts <<-ERROR
            
            Error!

            You need to define the name of your SSH key(s)
            e.g. ssh_options[:keys] = %w(/Users/your_username/.ssh/id_rsa)

            You can put this in your .caprc file in your home directory.

            ERROR
            exit
          end
          keys = ssh_options[:keys].collect{|key| File.read(key+'.pub')}.join("\n")
        else
          key_file = "config/ssh/authorized_keys/#{target_user}"
          if File.readable?(key_file)
            keys = File.read(key_file)
          else
            puts "Error! Could not find file '#{key_file}'"
            exit
          end
        end
        
        deprec2.mkdir(File.dirname(git_keys_file), :mode => 0700, :owner => git_user, :group => git_group, :via => :sudo)
        std.su_put(keys, "#{git_keys_file}-#{target_user}", '/tmp', :mode => 0600 )
        regenerate_authorized_keys
      end

      task :del_user do
        users = user_list
        default(:target_user) { 
          Capistrano::CLI.ui.choose do |q|
            users.each {|user| q.choice user}
          end
        }
        puts "Select a user to remove git access from."
        sudo "rm #{git_keys_file}-#{target_user}"
        regenerate_authorized_keys
      end
      
      task :list_users do
        users = user_list
        puts "Git users:"
        puts users.join("\n")
      end
      
      task :create_remote do
        
        # Create local git repo if missing
        if ! File.directory?('.git')
          system('git init')
          create_gitignore
          create_files_in_empty_dirs
          system("git add . && git commit -m 'initial import'")
        end
         
        # Push to remote git repo
        hostname = capture "echo $CAPISTRANO:HOST$"
        system "git remote add origin git@#{hostname.chomp}:#{application}"
        system "git push origin master:refs/heads/master"
        
        puts 
        puts "New remote Git repo: #{git_user}@#{hostname.chomp}:#{application}"
        puts    
        
        # Probably want to add this to .git/config
        #
        puts 'Add the following to .git/config'
        puts '[branch "master"]'
        puts ' remote = origin'
        puts ' merge = refs/heads/master'
          
      end
      
      task :create_gitignore do
        system("echo '.DS_Store' >> .gitignore") # files sometimes created by OSX 
        system("echo 'log/*' >> .gitignore") if File.directory?('log')
        system("echo 'tmp/**/*' >> .gitignore") if File.directory?('tmp')
      end
      
      task :create_files_in_empty_dirs do
        %w(log tmp).each { |dir| 
          system("touch #{dir}/.gitignore") if File.directory?(dir)
        }
      end
      
      # Returns an array of users who have ssh access to git account
      # Warning: Capistrano's capture only checks first server in list
      # so keep them all in sync or act on one git repo only
      task :user_list do
        result = capture "ls #{git_keys_file}-* | perl -pi -e 's/.*#{File.basename(git_keys_file)}-//'", :via => :sudo
        result.split("\n")
      end

      # Create root dir for git repositories
      task :create_git_root do
        deprec2.mkdir(git_root, :mode => 02775, :owner => git_user, :group => git_group, :via => :sudo)
        sudo "chmod -R g+w #{git_root}"
      end
      
      # task :create_git_user do
      #   deprec2.groupadd(git_group) 
      #   deprec2.useradd(git_user, :group => git_group, :shell => '/usr/local/bin/git-shell')
      #   # Set the primary group for the git user (in case user already existed
      #   # when previous command was run)
      #   sudo "usermod --gid #{git_group} #{git_user}"
      #   sudo "passwd --unlock #{git_user}"
      # end
      
      # regenerate git authorized keys file from users file in same dir
      task :regenerate_authorized_keys do
        sudo "echo '' > #{git_keys_file}"
        sudo "for file in `ls #{git_keys_file}-*`; do cat $file >> #{git_keys_file}; echo \"\n\" >> #{git_keys_file} ; done"
        sudo "chown #{git_user}.#{git_group} #{git_keys_file}"
        sudo "chmod 0600 #{git_keys_file}" 
      end


    end 
  end
end
