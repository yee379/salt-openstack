{% for service in ( 'openstack-cinder-api', 'openstack-cinder-scheduler', 'openstack-cinder-volume', 'openstack-glance-api', 'openstack-glance-registry', 'openstack-heat-api-cfn', 'openstack-heat-api', 'openstack-heat-engine', 'openstack-nova-api', 'openstack-nova-cert',  'openstack-nova-conductor', 'openstack-nova-consoleauth', 'openstack-nova-novncproxy', 'openstack-nova-scheduler', 'openstack-nova-compute', 'neutron-dhcp-agent', 'neutron-l3-agent', 'neutron-metadata-agent', 'neutron-openvswitch-agent', 'neutron-server', 'httpd', 'haproxy' ) %}
ensure openstack service {{ service }} is up:
  service.running:
    - name: {{ service }}
{% endfor %}