cloudsend
=========

This role is based on a script called cloudsend by [tavinus](https://github.com/tavinus). Hence the same name. The program *log_compress_and_send*  uses  this script to upload files and compressed folders to an ownCloud folder.

Requirements
------------

To upload files to the ownCloud folder, a public link to this folder is necessary and optionaly, but recommendet, a password.

Role Variables
--------------

There are no role variables.

Dependencies
------------

There are no Galaxy dependencies. Only built in roles are used.

Example Playbook
----------------

Including an example of how to use your role (for instance, with variables passed in as parameters) is always nice for users too:

    - hosts: servers
      roles:
         - cloudsend

License
-------

BSD

Author Information
------------------

Max Daiber-Huppert

Mail: [mdh@ipa.fhg.de](mailto:max.daiber-huppert@ipa.fraunhofer.de?subject=ansible&nbsp;role:&nbsp;cloudsend)
