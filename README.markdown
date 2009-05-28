- Introduction
- Helpful Links
- Installation
- Available Methods

Padlock Authorization Plugin
============================

###*Simple object-based role authorization*

Padlock allows easy object-based (rather than just global) role authorization functionality to ActiveRecord.
It adds a "padlock" method to the controller that "locks" specified actions and gets
"unlocked" only if passed a block that resolves to "true".

To padlock specific controller actions for a Project object you may do something like...

    padlock(:only => :destroy) { has_role? :owner, Project.find(params[:id]) }

or use `:on` if it makes more sense to you.  You can also use `:except` or `:on_all_except`

    padlock(:on => :index) { has_role? :owner, Project.find(params[:id]) }

> **In other words:**  *Place a padlock on these (actions) and unlock only if this (block) is true*

The block is just pure Ruby, so you could put any additional ||, &&, !, etc.  It will only
"unlock" the padlock if the block is true.  The contrived example below would unlock all actions
for this controller if the current day of the month is between 7 and 13...

    padlock { (7..13).include? Time.now.day }
    
Here are a few more examples:
    
    # for all actions other than :index, only allow users with an admin or manager role
    on the specific Room object
    padlock(:on_all_except => :index) { has_role? [:admin, :manager], Room.find(params[:id])}
    
    # only admins of the specified project or editors/owners of the current Team can access the destroy method
    padlock(:on => :destroy) { has_role?(:admin, Project.find(params[:id]) || has_role?([:editor, :owner], Team.find(@current_team))}

Padlock also adds numerous methods to both the User and authorizable models to manage roles.  Here
are just a few examples:

#### User (add "acts\_as\_authorized\_user" to the User model)

    @user.has_role? [:manager, :editor, :admin], @project
    @user.has_role :admin, @project 
    @user.has_no_role :admin, @project
    @user.has_no_roles_on @project
    @user.has_no_roles
    @user.has_what_with_role :owner, "Project"
    @user.has_what_roles_on @project 
    
#### Authorizable Objects (add "acts\_as\_authorizable" to the authorizable model)

    @project.accepts_role? :admin, @user
    @project.accepts_role :admin, @user
    @project.accepts_no_role :admin, @user
    @project.accepts_who_with_role [:editor, :manager, :delegate]
    @project.accepts_what_roles_by @user

The User gets these "has" methods by adding `acts_as_authorized_user` to the User model.  Authorizable
objects (including Users) can get the "accepts" methods by adding `acts_as_authorizable` to the model.
Detailed examples for each available method are discussed below under "Available Methods". 



Why another Authorization plugin?
---------------------------------

That's a good question.  

I had a few requirements to satisfy the needs of my applications:

1. Should have database-manageable roles
2. Should have ALL roles associated with an object
3. Should be usable in the controller with almost pure Ruby rather than a special DSL

There are a lot of authorization plugins that make it easy
to authorize a user for one or many actions based upon global roles.  
However, I had the need to make it reasonably simple to authorize
based upon roles associated with an object. (i.e. "admin" role on a Project.find(14))

Therefore, a major assumption of this plugin is that ALL roles are associated with an object.
As far as the authorization routines are concerned, there is no such thing as a 
"global" or "class" role.  

### This sucks!  All I want is global roles!

This is probably overkill for apps that only need global roles.  I would recommend Tim Harper's 
[role_requirement](http://github.com/timcharper/role_requirement/) plugin for global roles 
(in fact, the controller portion of this plugin is mostly just a twist on the code from that plugin).

That being said, there is nothing stopping you from easily mimicking global roles in your
application.  For instance, if you wanted to create a few "global" roles, just create an 
"App" or "Site" model (or whatever makes sense to you) with a single record.  

Then in "application.rb" insert a method like the following:
    
    def has_global_role?(role_names)
      has_role? role_names, App.first
    end
    
    helper_method :has_global_role?
    
This wraps the `has_role?` method and will allow this sort of language in your controller:

    # prevent all actions in this controller unless the current_user has a global role of :admin 
    padlock { has_global_role? :admin }
    
    # prevent the :destroy action unless global role of :admin, :manager, or :editor
    padlock( :on => :destroy ) { has_global_role? [:admin, :manager, :editor] }

Note that in the above I also made this a helper method for usage in the view.  It should also be noted
that the `has_role?` method is actually a wrapper of `current_user.has_role?`.  Thus, you could 
use either `has_role?` or `current_user.has_role?` in the view to query the current_user's roles.
Any other "has" or "accepts" methods can be used in the view, but will need to be sent to
the User or authorizable object, rather than as bareword methods.
    
A nice side effect of this is that it sets you up nicely in the event that you have multiple
contexts, sites, subdomains using this application.

You could do the same thing to mimic Class or Controller roles.  Just wrap the has_role? method
and you're good to go.

There are also already plugins that do object-based authorization.  Many of the thoughts and
code for the User and Model methods are actually derived from Bill Katz's impressive [Authorization
plugin](http://github.com/DocSavage/rails-authorization-plugin/).  That plugin actually introduces
a parser that will authorize in the controller with statements like "'inner circle' of :founder" or 
"attendees of :meeting or swedish\_mensa\_supermodels".
Very cool, but it seemed like I was spending more time getting the wording right than anything.  For
that reason, I just wanted pure Ruby.  The authorization plugin also has a ton of other stuff and
you can actually remove the parser stuff if you want.  Even so, I wanted a few different methods, as
well as, different methods names for a few.

Additionally, the Authorization plugin allows assignment of roles as global, Class or object.  For 
the sake of consistency and avoidance of mistakenly assigning global roles, I chose to change this
to only allow object roles.

And there you have it.


Helpful Links
=============

- Google group: <http://groups.google.com/group/padlock_authorization>
- Bugs: <http://github.com/baldwindavid/padlock_authorization/issues>

If you find a bug or a problem please post it on the github repo issue tracker. If you need help with something, please use google groups. I check both regularly and get emails when anything happens, so that is the best place to get help. This also benefits other people in the future with the same questions / problems. Thank you. 

Installation
==========================

Installation of this plugin takes about 2 minutes.

    1. Install the plugin into vendor/plugins
    2. run "script/generate padlock" to create the Role model and migration
    3. run "rake db:migrate" to create the roles and roles_users tables
    4. Add "include PadlockAuthorization" to your application.rb file (below "AuthenticatedSystem")
    5. Add "acts_as_authorizable" to any models that you want to accept roles
    6. Add "acts_as_authorized_user" to your User model
    
You're all set!

### Dependencies

Padlock adds functionality to ActiveRecord, so that is a necessity.  Beyond that, it needs a `current_user` method that holds a user object.  It also needs an `access_denied` method, so that it knows where to send a user should they be denied access to a page.

Both the `current_user` and `access_denied` methods are provided by default in restful-authentication.

If you like Authlogic for authentication (I do), you will probably already have a `current_user` method if you got it working.  The necessary `access_denied` method can be added directly to your Application controller.  This is the method pulled from restful-authentication and should work just fine for Authlogic...

    def access_denied
      respond_to do |format|
        format.html do
          store_location
          redirect_to new_user_session_path
        end
        # format.any doesn't work in rails version < http://dev.rubyonrails.org/changeset/8987
        # Add any other API formats here.  Some browsers send Accept: */* and 
        # trigger the 'format.any' block incorrectly.
        format.any(:json, :xml) do
          request_http_basic_authentication 'Web Password'
        end
      end
    end


Available Methods
==================================

User Extensions
-----------------------------------

#### These methods become available when `acts_as_authorized_user` is added to the User model.

### Associations

    roles

This will scope the roles down to those owned by the User.

    Examples:
    @user.roles
    @user.roles.find_all_by_authorizable_type('Project')
    
**Note:** The methods below already handle these examples, so you may never actually
need to use @user.roles. 

---

### Instance Methods

**Check for existence of a role or roles on an object:**

    has_role?( role_names, authorizable_obj )

> **In other words:**  *Does this (user) have this (role) on this (object)?*

    Examples:
    @user.has_role? :admin, @project
    @user.has_role? 'admin', @project
    @user.has_role? [:manager, :editor, :admin], @project
     
---

**Create a role on an object:**

    has_role( role_name, authorizable_obj )

> **In other words:**  *This (user) has this (role) on this (object).*

    Example:
    @user.has_role :admin, @project  

---
    
**Remove a single role that a user has on an object:**

    has_no_role( role_name, authorizable_obj )

> **In other words:**  *This (user) does not have this (role) on this (object)*
    
    Example:
    @user.has_no_role :admin, @project

---

**Remove all user's roles on a specific object:**
      
    has_no_roles_on(authorizable_obj)

> **In other words:**  *This (user) has no roles on this (object).*  
    
    Example:
    @user.has_no_roles_on @project

---
    
**Remove ALL roles for this user on ALL objects:**

    has_no_roles

> **In other words:**  *This (user) has no roles on any object.*
    
    Example:
    @user.has_no_roles

---
    
**Get all roles that a user has on a given object:**

    has_what_roles_on( authorizable_obj )

> **In other words:**  *This (user) has what roles on this (object)?*
    
    Example:
    @user.has_what_roles_on @project 
          # => ['admin', 'delegate', 'friend']

---
          
**Get all objects of a given class in which user has a given role or roles:**

    has_what_with_role( role_name, authorizable_class )

> **In other words:**  *This (user) has what objects with this (role) for this (Class name)* 

    Examples:
    @user.has_what_with_role :owner, "Project"
          # => [#<Project1>, #<Project2>, etc...]
                      
    @user.has_what_with_role [:owner, :admin, :editor], "Project"
          # => [#<Project1>, #<Project2>, etc...]

    

Model Extensions
---------------------------------------

#### These methods become available to models with `acts_as_authorizable` (including User model)

### Associations

    accepted_roles

This will scope all accepted roles down to those on this object.

    Examples:
    @project.accepted_roles
    @project.accepted_roles.find_all_by_authorizable_type('Project')

**Note:** The methods below already handle these examples, so you may never actually
need to use @project.accepted_roles.

---

    users

This will scope all of accepted roles down to those on this object.

    Examples:
    @project.users
    @project.users.find_by_email('john@doe.com')

**Note:** The methods below already handle these examples, so you may never actually
need to use @project.users.

---

### Instance Methods

**Check for existence of a role or roles on this object by a specified user:**
    
    accepts_role?( role_name, user )

> **In other words:**  *Does this (object) accept this (role) by this (user)?*
    
    Example:
    @project.accepts_role? :admin, @user

---
    
**Add the specified role to the specified user:**

    accepts_role( role_name, user )
    
> **In other words:**  *This (object) accepts this (role) by this (user).*
    
    Example:
    @project.accepts_role :admin, @user

---
    
**Remove the specified role of a specified user on this object:**

    accepts_no_role( role_name, user )

> **In other words:**  *This (object) does not accept this (role) by this (user).*
    
    Example:
    @project.accepts_no_role :admin, @user

---
    
**Get array of roles that a specified user has on an object:**

    accepts_what_roles_by( user )
    
> **In other words:**  *This (object) accepts what roles by this (user)?*
    
    Example:
    @project.accepts_what_roles_by @user
            # => ['admin', 'delegate', 'friend']

---

**Get array of users that have the specified role or roles on an object:**

    accepts_who_with_role( role_name )
    
> **In other words:**  *This (object) accepts which users with this (role)?*

    Examples:
    @project.accepts_who_with_role :editor
            # => [#<User1>, #<User2>, etc...]
    @project.accepts_who_with_role [:editor, :manager, :delegate]
            # => [#<User1>, #<User2>, etc...]