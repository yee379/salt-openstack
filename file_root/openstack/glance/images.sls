{% set glance = salt['openstack_utils.glance']() %}
{% set keystone_service = salt['openstack_utils.service_urls']( 'keystone', by_ip=True ) %}
{% set openstack_parameters = salt['openstack_utils.openstack_parameters']() %}


{% for image in glance['images'] %}
  {% set users = salt['openstack_utils.openstack_users'](glance['images'][image]['tenant']) %}
glance_{{ image }}_create:
  glance.image_present:
    - name: {{ image }}
    - connection_user: {{ glance['images'][image]['user'] }}
    - connection_tenant: {{ glance['images'][image]['tenant'] }}
    - connection_password: {{ users[glance['images'][image]['user']]['password'] }}
    - connection_auth_url: {{ keystone_service['public_with_version'] }}
    - connection_insecure: {{ salt['pillar.get']( 'ssl_insecure', False ) }}
    - connection_version: {{ keystone_service['version'] }}
  {% for param in glance['images'][image]['parameters'] %}
    - {{ param }}: {{ glance['images'][image]['parameters'][param] }}
  {% endfor %}
  {% if salt['openstack_utils.compare_ignore_case'](openstack_parameters['reset'], 'soft') %}
    - require:
      - cmd: glance_reset
  {% endif %}
{% endfor %}
