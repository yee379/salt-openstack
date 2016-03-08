{% set keystone = salt['openstack_utils.keystone']() %}
{% set openstack_parameters = salt['openstack_utils.openstack_parameters']() %}
{% set keystone_service = salt['openstack_utils.service_urls']( 'keystone', by_ip=True ) %}

{% for tenant_name in keystone['openstack_tenants'] %}
  {% set tenant_users = salt['openstack_utils.openstack_users'](tenant_name) %}
  {% for user in tenant_users %}
keystone_{{ user }}_user_in_{{ tenant_name }}:
  keystone:
    - user_present
    - name: {{ user }}
    - password: {{ tenant_users[user]['password'] }}
    - email: {{ tenant_users[user]['email'] }}
    - tenant: {{ tenant_name }}
    - roles:
      - {{ tenant_name }}: {{ tenant_users[user]['roles'] }}
    - connection_token: "{{ keystone['admin_token'] }}"
    - connection_endpoint: {{ keystone_service['admin_with_version'] }}
    - connection_insecure: {{ salt['pillar.get']( 'ssl_insecure', False ) }}
    {% if salt['openstack_utils.compare_ignore_case'](openstack_parameters['reset'], 'soft') %}
    - require:
      - cmd: keystone_reset
    {% endif %}

    {% if tenant_users[user].has_key('keystonerc') and
          tenant_users[user]['keystonerc'].has_key('create') and
          salt['openstack_utils.boolean_value'](tenant_users[user]['keystonerc']['create']) %}
keystonerc_{{ user }}_in_{{ tenant_name }}_create:
  file.managed:
    - name: {{ tenant_users[user]['keystonerc']['path'] }}
    - contents: |
        export OS_USERNAME={{ user }}
        export OS_PROJECT_NAME={{ tenant_name }}
        export OS_TENANT_NAME={{ tenant_name }}
        export OS_PASSWORD={{ tenant_users[user]['password'] }}
        export OS_AUTH_URL={{ keystone_service['public_with_version'] }}
        export OS_VOLUME_API_VERSION=2
        export OS_IMAGE_API_VERSION=2
        export PS1='[\u@\h \W(keystonerc_{{ user }}:{{ tenant_name }})]\$ '
    - require:
      - keystone: keystone_{{ user }}_user_in_{{ tenant_name }}
    {% endif %}
  {% endfor %}
{% endfor %}
