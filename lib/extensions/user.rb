# NOTE:  The majority of the code for this portion of the plugin
# is from Bill Katz excellent Authorization Plugin
# (http://github.com/DocSavage/rails-authorization-plugin/)

module PadlockAuthorization
  module Extensions

    module UserExtensions
      def self.included( recipient )
        recipient.extend( ClassMethods )
      end

      module ClassMethods
        def acts_as_authorized_user
          has_and_belongs_to_many :roles
          include PadlockAuthorization::Extensions::UserExtensions::InstanceMethods
        end
      end

      module InstanceMethods
        
        # Does this (user) have this (role) on this (object)?
        
        # Use a string or a symbol
          # @user.has_role? :admin, @project
          # @user.has_role? 'admin', @project
        
        # Query multiple roles at once...  
        # Does this (user) have one of these (roles) on this (object)? 
          # @user.has_role? [:manager, :admin], @project
        def has_role?( role_names, authorizable_obj )       
          prepare_role_names(role_names).each do |role_name| 
            role = get_role( role_name, authorizable_obj )
            if role
              return true if self.roles.exists?( role.id ) 
            end
          end
          return false
        end
        
        # This (user) has this (role) on this (object).
        # Assign a role to user
          # @user.has_role :admin, @project
        def has_role( role_name, authorizable_obj )
          role_name = role_name.to_s
          role = get_role( role_name, authorizable_obj )          
          role = Role.create( :name => role_name, :authorizable => authorizable_obj ) if role.nil?
          self.roles << role if role and not self.roles.exists?( role.id )
        end

        # This (user) does not have this (role) on this (object)
        # Remove a single role that a user has on an object
          # @user.has_no_role :admin, @project
        def has_no_role( role_name, authorizable_obj )
          role_name = role_name.to_s
          role = get_role( role_name, authorizable_obj )
          delete_role( role )
        end
        
        # This (user) has no roles on this (object).
        # remove all user's roles on a specific object
          # @user.has_no_roles_on @project
        def has_no_roles_on(authorizable_obj)
          self.find_all_by_authorizable(authorizable_obj).each { |role| delete_role( role ) }
        end
        
        # This (user) has no roles on any object.
        # remove ALL roles for this user on ALL objects
          # @user.has_no_roles
        def has_no_roles
          self.roles.each { |role| delete_role( role ) }
        end

        # This (user) has what roles on this (object)?
        # Get all roles that a user has on a given object
          # @user.has_what_roles_on @project 
                    # => ['admin', 'delegate', 'friend']
        def has_what_roles_on( authorizable_obj )
          self.find_all_by_authorizable(authorizable_obj).collect(&:name)
        end

        # This (user) has what objects with this (role) for this (Class name)
        # get all objects of a given class in which user has a given role or roles
          # @user.has_what_with_role :owner, Project
                    # => [#<Project1>, #<Project2>, etc...]
        
        # This (user) has what objects with these (roles) for this (Class name)              
          # @user.has_what_with_role [:owner, :admin, :editor], Project
                    # => [#<Project1>, #<Project2>, etc...]
        def has_what_with_role( role_names, authorizable_class )
          role_names = prepare_role_names(role_names)
          authorizable_class.constantize.find(
            self.roles.find(:all, :conditions => ['authorizable_type = ? AND name IN (?)', authorizable_class, role_names]).collect(&:authorizable_id).uniq
          )
        end
           
        
        
        
        

        def find_all_by_authorizable(authorizable_obj)          self.roles.find_all_by_authorizable_type_and_authorizable_id(authorizable_obj.class.to_s, authorizable_obj.id )
        end
        

        private

        def get_role( role_name, authorizable_obj )
            Role.find( :first,
                       :conditions => [ 'name = ? AND authorizable_type = ? AND authorizable_id = ?',
                                        role_name, authorizable_obj.class.to_s, authorizable_obj.id ] )
        end
        
        # convert role names to array and names within to strings if not already
        def prepare_role_names(role_names)
          Array(role_names).collect! {|role_name| role_name.to_s }   
        end
        

        def delete_role( role ) 
          if role
            self.roles.delete( role )
            role.destroy if role.users.empty?
          end
        end

      end
    end

  end
end

