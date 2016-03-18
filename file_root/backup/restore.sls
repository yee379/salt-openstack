download gz mysql sql backup:
  cmd.run:
    - name: curl -L http://www.slac.stanford.edu/~ytl/openstack.sql.gz -o /tmp/openstack.sql.gz
    - creates:  /tmp/openstack.sql.gz
    
{% for service in ( 'openstack-cinder-api', 'openstack-cinder-scheduler', 'openstack-cinder-volume', 'openstack-glance-api', 'openstack-glance-registry', 'openstack-heat-api-cfn', 'openstack-heat-api', 'openstack-heat-engine', 'openstack-nova-api', 'openstack-nova-cert', 'openstack-nova-compute', 'openstack-nova-conductor', 'openstack-nova-consoleauth', 'openstack-nova-novncproxy', 'openstack-nova-scheduler', 'neutron-dhcp-agent', 'neutron-l3-agent', 'neutron-metadata-agent', 'neutron-openvswitch-agent', 'neutron-server', 'httpd' ) %}
ensure openstack service {{ service }} is off:
  service.dead:
    - name: {{ service }}
    - require:
      - cmd: download gz mysql sql backup
    - require_in: 
      - cmd: restore mysql backup
{% endfor %}

restore mysql backup:
  cmd.run:
    - name: mysql -u root -p change_me < zcat /tmp/openstack.sql.gz
    - require:
      - cmd: download gz mysql sql backup
