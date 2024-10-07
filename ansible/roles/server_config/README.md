Server Config
=========

Configure ubuntu based servers

* logrotate
* ufw management
* system update
* time date
* base soft management
* set hostname
* fail2ban
* SSMTP

Role Variables
--------------

A description of the settable variables for this role should go here, including any variables that are in defaults/main.yml, vars/main.yml, and any variables that can/should be set via parameters to the role. Any variables that are read from other roles and/or the global scope (ie. hostvars, group vars, etc.) should be mentioned here as well.

Dependencies
------------

AUR module
git clone https://github.com/kewlfft/ansible-aur.git ~/.ansible/plugins/modules/aur

Example Playbook
----------------

Including an example of how to use your role (for instance, with variables passed in as parameters) is always nice for users too:

    - hosts: servers
      roles:
         - { role: username.rolename, x: 42 }

License
-------

MIT

Author Information
------------------

Klimenko Maxim Sergievich klimenkomaximsergievich@gmail.com
