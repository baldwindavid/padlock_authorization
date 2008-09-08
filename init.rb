ActiveRecord::Base.send( :include,
      PadlockAuthorization::Extensions::RoleExtensions,
      PadlockAuthorization::Extensions::UserExtensions,
      PadlockAuthorization::Extensions::ModelExtensions
    )