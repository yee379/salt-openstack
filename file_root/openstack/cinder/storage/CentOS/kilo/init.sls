{% set cinder = salt['openstack_utils.cinder']() %}
{% set service_users = salt['openstack_utils.openstack_users']('service') %}
{% set openstack_parameters = salt['openstack_utils.openstack_parameters']() %}
{% set keystone_auth = salt['openstack_utils.keystone_auth']( by_ip=True ) %}

include:
  - openstack.cinder.message_queue.{{ openstack_parameters['series'] }}.{{ openstack_parameters['message_queue'] }}

cinder_storage_conf:
  ini.options_present:
    - name: "{{ cinder['conf']['cinder'] }}"
    - sections:
        database:
          connection: "mysql://{{ cinder['database']['username'] }}:{{ cinder['database']['password'] }}@{{ openstack_parameters['controller_ip'] }}/{{ cinder['database']['db_name'] }}"
        DEFAULT:
          my_ip: "{{ salt['openstack_utils.minion_ip'](grains['id']) }}"
          glance_host: "{{ openstack_parameters['controller_ip'] }}"
          auth_strategy: keystone
          enabled_backends: lvm
          debug: "{{ salt['openstack_utils.boolean_value'](openstack_parameters['debug_mode']) }}"
          verbose: "{{ salt['openstack_utils.boolean_value'](openstack_parameters['debug_mode']) }}"
          glance_api_insecure: {{ salt['pillar.get']( 'ssl_insecure', False ) }}
        keystone_authtoken: 
          insecure: {{ salt['pillar.get']( 'ssl_insecure', False ) }}
          auth_uri: {{ keystone_auth['public'] }}
          auth_url: {{ keystone_auth['admin'] }}
          auth_plugin: "password"
          project_domain_id: "default"
          user_domain_id: "default"
          project_name: "service"
          username: "cinder"
          password: "{{ service_users['cinder']['password'] }}"
        lvm:
          volume_driver: cinder.volume.drivers.lvm.LVMVolumeDriver
          volume_group: {{ cinder['volumes_group_name'] }}
          iscsi_protocol: iscsi
          iscsi_helper: lioadm
        oslo_concurrency:
          lock_path: "{{ cinder['files']['lock'] }}"
    - require:
{% for pkg in cinder['packages']['storage'] %}
        - pkg: cinder_storage_{{ pkg }}_install
{% endfor %}


{% for service in cinder['services']['storage'] %}
cinder_storage_{{ service }}_running:
  service.running:
    - enable: True
    - name: {{ cinder['services']['storage'][service] }}
    - watch:
      - ini: cinder_storage_conf
{% endfor %}


cinder_storage_wait:
  cmd.run:
    - name: sleep 5
    - require:
{% for service in cinder['services']['storage'] %}
      - service: cinder_storage_{{ service }}_running
{% endfor %}
