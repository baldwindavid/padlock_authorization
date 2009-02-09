# NOTE:  The majority of the code for this portion of the plugin
# is from Bill Katz excellent Authorization Plugin
# (http://github.com/DocSavage/rails-authorization-plugin/)

module PadlockAuthorization
  module Extensions

    module ModelExtensions
      def self.included( recipient )
        recipient.extend( ClassMethods )
      end

      module ClassMethods
        def acts_as_authorizable
          has_many :accepted_roles, :as => :authorizable, :class_name => 'Role', :dependent => :destroy
          
          has_many :users, :finder_sql => 'SELECT DISTINCT users.* FROM users INNER JOIN roles_users ON user_id = users.#{User.primary_key} INNER JOIN roles ON roles.id = role_id WHERE authorizable_type = \'#{self.class.base_class.to_s}\' AND authorizable_id = #{id}', :counter_sql => 'SELECT COUNT(DISTINCT users.#{User.primary_key}) FROM users INNER JOIN roles_users ON user_id = users.#{User.primary_key} INNER JOIN roles ON roles.id = role_id WHERE authorizable_type = \'#{self.class.base_class.to_s}\' AND authorizable_id = #{id}', :readonly => true


          include PadlockAuthorization::Extensions::ModelExtensions::InstanceMethods
        end
      end

      module InstanceMethods
        
        # Does this (object) accept this (role) by this (user)?
          # @project.accepts_role? :admin, @user
        def accepts_role?( role_name, user )
          user.has_role? role_name, self
        end

        # This (object) accepts this (role) by this (user).
        # add the specified role to the specified user
          # @project.accepts_role :admin, @user
        def accepts_role( role_name, user )
          user.has_role role_name, self
        end

        # This (object) does not accept this (role) by this (user).
        # remove the specified role of a specified user on this object
          # @project.accepts_no_role :admin, @user
        def accepts_no_role( role_name, user )
          user.has_no_role role_name, self
        end
        
        # This (object) accepts what roles by this (user)?
        # returns array of roles that a specified user has on an object
          # @project.accepts_what_roles_by @user
                  # => ['admin', 'delegate', 'friend']
        def accepts_what_roles_by( user )
          user.has_what_roles_on self
        end
        
        # This (object) accepts which users with this (role)?   
        # returns array of users that have the specified role or roles on an object
          # @project.accepts_who_with_role :editor
                  # => [#<User1>, #<User2>, etc...]
                  
        # This (object) accepts which users with these (roles)?
          # @project.accepts_who_with_role [:editor, :manager, :delegate]
                  # => [#<User1>, #<User2>, etc...]
        def accepts_who_with_role( role_name )
          self.users.select {|u| u.has_role? role_name, self}       
        end

      end
    end

  end
end

