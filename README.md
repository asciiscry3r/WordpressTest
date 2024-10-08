## Cloud and local components of this test task 
====================

    * AWS RDS
    * AWS VPC
    * AWS EC2
    * AWS Elastic Cache Redis
    * https://wordpress.mksscryertower.quest/ - result of this work 
    * Terraform
    * Ansible
    * Bash
    * GitHub Actions
    * Ubuntu 20.04

Time - about 10 hours with distraction

### Code
=====================

#### Ansible playbook

```
---
- hosts: all

  roles:
    - name: server_config
      become: yes
      become_user: root
      tags: configure

- hosts: wordpress

  roles:
    - name: php
      become: yes
      become_user: root
      tags: php
    - name: nginx
      become: yes
      become_user: root
      tags: nginx

```
In roles i use my own part of code and other are written from scratch:

Main variables are self explained:
```
server_name: wordpress.mksscryertower.quest
install_php: true
php_version: 8.2
server_root_folder: /var/www/mkssite
server_web_user: www-data
server_timezone: "Europe/Kiev"
server_admin_email: klimenkomaximsergievich@gmail.com
journal_vacuum_size: "500M"
journal_vacuum_time: "90d"
server_apps:
  - name: dnsutils
    state: present
  - name: net-tools
    state: present
......
......
```
customization avaliable trought offical documentation

#### Terraform

Im use my own module for EC2, because time, and other described in terraform/servers.tf. This is are SG setting, RDS settings, VPC settings and other.

customization avaliable trought offical documentation

#### GitHub Action

I try this CICD tool in first time, decide to use only simple bash scripts on server and run it after setting db host and password:

```
#!/usr/bin/env bash

DATABASE_HOST=$1
DATABASE_PASSWORD=$2

cd /home/ubuntu

if [ -d WordpressTest ]
then
	cd WordpressTest && git pull --force
else
	git clone https://github.com/asciiscry3r/WordpressTest.git
fi

cd /home/ubuntu

rsync -avP WordpressTest/wordpress/ /var/www/mkssite/

cp /home/ubuntu/wp-config.php /var/www/mkssite/wp-config.php

sudo sed -i "s/DATABASEPASSPLACEHOLDER/${DATABASE_PASSWORD}/g" /var/www/mkssite/wp-config.php
sudo sed -i "s/DATABASEHOSTPLACEHOLDER/${DATABASE_HOST}/g" /var/www/mkssite/wp-config.php

sudo systemctl restart php8.2-fpm
sudo systemctl restart nginx

sudo chown -R www-data:www-data /var/www/mkssite/

```

#### Redis

I find WP Redis plugin absolutely useless without paing for him. My workaround is this redis proxy:

```
nutcracker -c config.yml

```

But wp for some "php plugin backend" related reason didnt see this local socket.

#### Deployment

Automatically after push to main

Latest deployment:
```
https://github.com/asciiscry3r/WordpressTest/actions/runs/11239496083/job/31246674228
```
### brief overview of the code structure:
```
├── ansible   Ansible folder
│   ├── host_vars   Variables for hosts
│   └── roles   Roles with different tasks
├── terraform   Terraform for AWS
│   └── modules   My module for EC2 
└── wordpress   Source code of Wordpress
    ├── wp-admin
    ├── wp-content
    └── wp-includes

.github/   CICD workflow instruction
└── workflows 
    ├── wordpress-deployments.yml
```
#### Fin