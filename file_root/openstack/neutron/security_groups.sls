{% set neutron = salt['openstack_utils.neutron'](grains['id']) %}
{% set keystone_service = salt['openstack_utils.service_urls']( 'keystone', by_ip=True ) %}
{% set openstack_parameters = salt['openstack_utils.openstack_parameters']() %}


{% for security_group in neutron['security_groups'] %}
openstack_security_group_{{ security_group }}:
  neutron.security_group_present:
    - name: {{ security_group }}
    - description: {{ neutron['security_groups'][security_group]['description'] }}
    - rules: {{ neutron['security_groups'][security_group]['rules'] }}
    - connection_user: {{ neutron['security_groups'][security_group]['user'] }}
    - connection_tenant: {{ neutron['security_groups'][security_group]['tenant'] }}
  {% set tenant_users = salt['openstack_utils.openstack_users'](neutron['security_groups'][security_group]['tenant']) %}
    - connection_password: {{ tenant_users[neutron['security_groups'][security_group]['user']]['password'] }}
    - connection_auth_url: {{ keystone_service['internal_with_version'] }}
    - connection_insecure: {{ salt['pillar.get']( 'ssl_insecure', False ) }}
    - connection_version: {{ keystone_service['version'] }}
  {% if salt['openstack_utils.compare_ignore_case'](openstack_parameters['reset'], 'soft') %}
    - require:
      - cmd: neutron_reset
  {% endif %}
{% endfor %}
