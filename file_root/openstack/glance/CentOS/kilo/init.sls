{% set glance = salt['openstack_utils.glance']() %}
{% set service_users = salt['openstack_utils.openstack_users']('service') %}
{% set openstack_parameters = salt['openstack_utils.openstack_parameters']() %}
{% set keystone_auth = salt['openstack_utils.keystone_auth']( by_ip=True ) %}

archive {{ glance['conf']['api'] }}:
  file.copy:
    - name: {{ glance['conf']['api'] }}.orig
    - source: {{ glance['conf']['api'] }}
    - unless: ls {{ glance['conf']['api'] }}.orig
    
glance_api_conf:
  ini.options_present:
    - name: "{{ glance['conf']['api'] }}"
    - sections: 
        database: 
          connection: "mysql://{{ glance['database']['username'] }}:{{ glance['database']['password'] }}@{{ openstack_parameters['controller_ip'] }}/{{ glance['database']['db_name'] }}"
        keystone_authtoken: 
          auth_uri: {{ keystone_auth['public'] }}
          auth_url: {{ keystone_auth['admin'] }}
          auth_plugin: "password"
          project_domain_id: "default"
          user_domain_id: "default"
          project_name: "service"
          username: "glance"
          password: "{{ service_users['glance']['password'] }}"
        paste_deploy: 
          flavor: keystone
        glance_store:
          default_store: file
          filesystem_store_datadir: {{ glance['files']['images_dir'] }}
        DEFAULT:
          notification_driver: noop
          debug: "{{ salt['openstack_utils.boolean_value'](openstack_parameters['debug_mode']) }}"
          verbose: "{{ salt['openstack_utils.boolean_value'](openstack_parameters['debug_mode']) }}"
    - require:
        - file: archive {{ glance['conf']['api'] }}
{% for pkg in glance['packages'] %}
        - pkg: glance_{{ pkg }}_install
{% endfor %}


glance_registry_conf:
  ini.options_present:
    - name: "{{ glance['conf']['registry'] }}"
    - sections:
        database:
          connection: "mysql://{{ glance['database']['username'] }}:{{ glance['database']['password'] }}@{{ openstack_parameters['controller_ip'] }}/{{ glance['database']['db_name'] }}"
        keystone_authtoken: 
          auth_uri: {{ keystone_auth['public'] }}
          auth_url: {{ keystone_auth['admin'] }}
          auth_plugin: "password"
          project_domain_id: "default"
          user_domain_id: "default"
          project_name: "service"
          username: "glance"
          password: "{{ service_users['glance']['password'] }}"
        paste_deploy: 
          flavor: keystone
        DEFAULT:
          notification_driver: noop
          debug: "{{ salt['openstack_utils.boolean_value'](openstack_parameters['debug_mode']) }}"
          verbose: "{{ salt['openstack_utils.boolean_value'](openstack_parameters['debug_mode']) }}"
    - require:
{% for pkg in glance['packages'] %}
        - pkg: glance_{{ pkg }}_install
{% endfor %}


glance_db_sync:
  cmd.run:
    - name: "su -s /bin/sh -c 'glance-manage db_sync' glance"
    - require:
      - ini: glance_api_conf
      - ini: glance_registry_conf


glance_registry_running:
  service.running:
    - enable: True
    - name: "{{ glance['services']['registry'] }}"
    - require:
      - cmd: glance_db_sync
    - watch:
      - ini: glance_registry_conf


glance_api_running:
  service.running:
    - enable: True
    - name: "{{ glance['services']['api'] }}"
    - require:
      - cmd: glance_db_sync
    - watch:
      - ini: glance_api_conf


glance_sqlite_delete:
  file.absent:
    - name: "{{ glance['files']['sqlite'] }}"
    - require: 
      - cmd: glance_db_sync


glance_wait:
  cmd.run:
    - name: sleep 5
    - require:
      - service: glance_registry_running
      - service: glance_api_running
