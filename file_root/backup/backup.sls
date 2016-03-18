backup openstack mysql database:
  cmd.run:
    - name: mysqldump --opt --all-databases | gzip > /tmp/openstack-{{ grains['id'] }}-{{ "now"|strftime }}.sql
    
