{% set cinder = salt['openstack_utils.cinder']() %}
{% set service_users = salt['openstack_utils.openstack_users']('service') %}
{% set openstack_parameters = salt['openstack_utils.openstack_parameters']() %}
{% set keystone_auth = salt['openstack_utils.keystone_auth']( by_ip=True ) %}

cinder_conf_create:
  file.copy:
    - name: "{{ cinder['conf']['cinder'] }}"
    - source: "{{ cinder['conf']['cinder_conf_dist'] }}"
    - user: cinder
    - group: cinder
    - require:
{% for pkg in cinder['packages']['controller'] %}
      - pkg: cinder_controller_{{ pkg }}_install
{% endfor %}

archive {{ cinder['conf']['cinder'] }}:
  file.copy:
    - name: {{ cinder['conf']['cinder'] }}.orig
    - source: {{ cinder['conf']['cinder'] }}
    - unless: ls {{ cinder['conf']['cinder'] }}.orig
    
cinder_controller_conf:
  ini.options_present:
    - name: "{{ cinder['conf']['cinder'] }}"
    - sections:
        DEFAULT:
          my_ip: {{ openstack_parameters['controller_ip'] }}
          auth_strategy: keystone
          debug: "{{ salt['openstack_utils.boolean_value'](openstack_parameters['debug_mode']) }}"
          verbose: "{{ salt['openstack_utils.boolean_value'](openstack_parameters['debug_mode']) }}"
          glance_api_insecure: {{ salt['pillar.get']( 'ssl_insecure', False ) }}
          # osapi_volume_listen: 
          osapi_volume_listen_port: {{ salt['openstack_utils.service_urls']( 'cinder', by_ip=True )['public_local_port'] }}
        database:
          connection: "mysql://{{ cinder['database']['username'] }}:{{ cinder['database']['password'] }}@{{ openstack_parameters['controller_ip'] }}/{{ cinder['database']['db_name'] }}"
        keystone_authtoken: 
          insecure: {{ salt['pillar.get']( 'ssl_insecure', False ) }}
          auth_uri: {{ keystone_auth['public_with_path'] }}
          auth_url: {{ keystone_auth['admin_with_path'] }}
          auth_plugin: "password"
          project_domain_id: "default"
          user_domain_id: "default"
          project_name: "service"
          username: "cinder"
          password: "{{ service_users['cinder']['password'] }}"
        oslo_concurrency:
          lock_path: "{{ cinder['files']['lock'] }}"
    - require:
      - file: archive {{ cinder['conf']['cinder'] }}
      - file: cinder_conf_create

cinder_db_sync:
  cmd.run:
    - name: "su -s /bin/sh -c 'cinder-manage db sync' cinder"
    - require:
      - ini: cinder_controller_conf


cinder_controller_sqlite_delete:
  file.absent:
    - name: {{ cinder['files']['sqlite'] }}
    - require:
      - cmd: cinder_db_sync


{% for service in cinder['services']['controller'] %}
cinder_controller_{{ service }}_running:
  service.running:
    - enable: True
    - name: {{ cinder['services']['controller'][service] }}
    - watch:
      - ini: cinder_controller_conf
{% endfor %}


cinder_controller_wait:
  cmd.run:
    - name: sleep 5
    - require:
{% for service in cinder['services']['controller'] %}
      - service: cinder_controller_{{ service }}_running
{% endfor %}
