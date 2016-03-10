ensure metrics script is installed:
  file.managed:
    - name: /usr/bin/openstack_metrics.py
    - source: salt://influxdb/openstack_metrics.py
    - user: root
    - group: root
    - mode: 755
    
cron to poll for metrics:
  cron.present:
    - user: root
    - name: 'source /root/keystonerc_admin; /usr/bin/openstack_metrics.py --insecure'
    - minute: '5'
    - hour: '*'
    - daymonth: '*'
    - month: '*'
    - dayweek: '*'
    - require:
      - file: ensure metrics script is installed
      
      
# TODO: add recipe to auto add database and user to influxdb
# > create database openstack
# > create user osmaint with password 'osmaint'
# > grant all on openstack to osmaint