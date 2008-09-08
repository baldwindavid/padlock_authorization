module PadlockAuthorization
  module Extensions
    
    module RoleExtensions
      def self.included( recipient )
        recipient.extend( ClassMethods )
      end
      
      module ClassMethods
        
        def acts_as_role
          has_and_belongs_to_many :users
          belongs_to :authorizable, :polymorphic => true
          include PadlockAuthorization::Extensions::RoleExtensions::InstanceMethods
        end
        
      end
      
      module InstanceMethods              
      end
      
    end

  end
end

