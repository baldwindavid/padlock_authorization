# NOTE:  The majority of the code for the controller portion of this plugin
# is from Tim Harper's excellent Role Requirement Plugin
# (http://github.com/timcharper/role_requirement/)

require File.dirname(__FILE__) + '/extensions/role'
require File.dirname(__FILE__) + '/extensions/user'
require File.dirname(__FILE__) + '/extensions/model'

# Main module for authentication.  
# Include this in ApplicationController to activate PadlockAuthorization
#
# See RoleSecurityClassMethods for some methods it provides.
module PadlockAuthorization

  def self.included(klass)
    klass.send :class_inheritable_array, :role_requirements
    klass.send :include, RoleSecurityInstanceMethods
    klass.send :extend, RoleSecurityClassMethods
    klass.send :helper_method, :has_role? 
    klass.send :role_requirements=, []
  end

  module RoleSecurityClassMethods
  
    def reset_role_requirements!
      self.role_requirements.clear
    end
  

    # Add this to the top of your controller to place a "padlock" on actions.
    # Only "unlock" the padlock if the (block) is true.
    
    # padlock(hash) {block}
    
    # Example Usage:
    # 
    # padlock(:only => [:edit, :update]) { has_role? :owner, Project.find(params[:id]) }
 
    
    # Valid options
  
    #  :only or :on - Only require the role for the given actions
    #  :except or :on_all_except - Require the role for everything but these actions 
   
    def padlock(options = {}, &unlock_if)
      options.assert_valid_keys(
        :only, :on, 
        :except, :on_all_except
      )
    
      # only declare that before filter once
      unless (@before_filter_declared||=false)
        @before_filter_declared=true
        before_filter :check_roles
      end
    
      options[:only] ||= options[:on] if options[:on]
      options[:except] ||= options[:on_all_except] if options[:on_all_except]
      options[:unlock_if] = unlock_if if unlock_if
      
      # convert any actions into symbols
      for key in [:only, :except]
        if options.has_key?(key)
          options[key] = [options[key]] unless Array === options[key]
          options[key] = options[key].compact.collect{|v| v.to_sym}
        end 
      end
          
      self.role_requirements||=[]
      self.role_requirements << {:options => options }
      
    end
  
    def user_authorized_for?(user, params = {}, instance = self)
      return true unless Array===self.role_requirements
      self.role_requirements.each{| role_requirement|
      
        options = role_requirement[:options]
        # do the options match the params?
      
        # check the action
        if options.has_key?(:only)
          next unless options[:only].include?( (params[:action]||"index").to_sym )
        end
      
        if options.has_key?(:except)
          next if options[:except].include?( (params[:action]||"index").to_sym)
        end
      
        if options.has_key?(:unlock_if)
          next if instance.instance_exec(params, &options[:unlock_if])
          return false
        end
        
        return false
                             
      }
    
      return true
    end
  end

  module RoleSecurityInstanceMethods
    
    def has_role?(role_name, authorizable_obj, current_user = current_user )
      if current_user
        current_user.has_role?(role_name, authorizable_obj)
      else
        false
      end
    end
  
    def access_denied
      if current_user
        render_optional_error_file(401)
        return false
      else
        super
      end
    end
  
    def check_roles       
      return access_denied unless self.class.user_authorized_for?(current_user, params, self)
      true
    end
  
  end


end