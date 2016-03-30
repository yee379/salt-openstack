{% set keystone = salt['openstack_utils.keystone']() %}
{% set openstack_parameters = salt['openstack_utils.openstack_parameters']() %}
{% set keystone_service = salt['openstack_utils.service_urls']( 'keystone', by_ip=True ) %}

{% for service_name in keystone['openstack_services'] %}
keystone_{{ service_name }}_service:
  keystone:
    - service_present
    - name: {{ service_name }}
    - service_type: {{ keystone['openstack_services'][service_name]['service_type'] }}
    - description: {{ keystone['openstack_services'][service_name]['description'] }}
    - connection_token: {{ keystone['admin_token'] }}
    - connection_endpoint: {{ keystone_service['admin_with_version'] }}
    - connection_insecure: {{ salt['pillar.get']( 'ssl_insecure', False ) }}
    - connection_version: {{ keystone_service['version'] }}
  {% if salt['openstack_utils.compare_ignore_case'](openstack_parameters['reset'], 'soft') %}
    - require:
      - cmd: keystone_reset
  {% endif %}

keystone_{{ service_name }}_endpoint:
  keystone:
    - endpoint_present
    - name: {{ service_name }}
    - publicurl: {{ keystone['openstack_services'][service_name]['endpoint']['publicurl'].format(openstack_parameters['controller_ip']) }}
    - adminurl: {{ keystone['openstack_services'][service_name]['endpoint']['adminurl'].format(openstack_parameters['controller_ip']) }}
    - internalurl: {{ keystone['openstack_services'][service_name]['endpoint']['internalurl'].format(openstack_parameters['controller_ip']) }}
    - region: "RegionOne"
    - connection_token: {{ keystone['admin_token'] }}
    - connection_endpoint: {{ keystone_service['admin_with_version'] }}
    - connection_insecure: {{ salt['pillar.get']( 'ssl_insecure', False ) }}
    - connection_version: {{ keystone_service['version'] }}
    - require:
      - keystone: keystone_{{ service_name }}_service
{% endfor %}
