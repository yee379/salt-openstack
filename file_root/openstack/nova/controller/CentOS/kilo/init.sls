{% set nova = salt['openstack_utils.nova']( grains['id'] ) %}
{% set neutron = salt['openstack_utils.neutron']() %}
{% set service_users = salt['openstack_utils.openstack_users']('service') %}
{% set openstack_parameters = salt['openstack_utils.openstack_parameters']() %}
{% set keystone_auth = salt['openstack_utils.keystone_auth']( by_ip=True ) %}

archive {{ nova['conf']['nova'] }} controller:
  file.copy:
    - name: {{ nova['conf']['nova'] }}.orig
    - source: {{ nova['conf']['nova'] }} 
    - unless: ls {{ nova['conf']['nova'] }}.orig

include:
  - openstack.nova.message_queue.{{ openstack_parameters['series'] }}.{{ openstack_parameters['message_queue'] }}
  - openstack.nova.policy_json

{% set minion_ip = salt['openstack_utils.minion_ip'](grains['id']) %}
nova_controller_conf:
  ini.options_present:
    - name: "{{ nova['conf']['nova'] }}"
    - sections:
        database:
          connection: "mysql://{{ nova['database']['username'] }}:{{ nova['database']['password'] }}@{{ openstack_parameters['controller_ip'] }}/{{ nova['database']['db_name'] }}"
        DEFAULT:
          auth_strategy: "keystone"
          my_ip: "{{ openstack_parameters['controller_ip'] }}"
          vncserver_listen: {{ minion_ip }}
          # osapi_compute_listen: 127.0.0.1
          osapi_compute_listen_port: {{ salt['openstack_utils.service_urls']( 'nova', by_ip=True )['public_local_port'] }}
          novncproxy_port: {{ salt['pillar.get']('services:novnc:url:public:local_port', 6080 ) }}
          vncserver_proxyclient_address: "{{ openstack_parameters['controller_ip'] }}"
          cpu_allocation_ratio: {{ nova['cpu_allocation_ratio'] }}
          ram_allocation_ratio: {{ nova['ram_allocation_ratio'] }}
          debug: "{{ salt['openstack_utils.boolean_value'](openstack_parameters['debug_mode']) }}"
          verbose: "{{ salt['openstack_utils.boolean_value'](openstack_parameters['verbose_mode']) }}"
          network_api_class: nova.network.neutronv2.api.API
          security_group_api: neutron
          linuxnet_interface_driver: nova.network.linux_net.LinuxOVSInterfaceDriver
          firewall_driver: nova.virt.firewall.NoopFirewallDriver
          glance_api_servers: {{ salt['openstack_utils.service_urls']( 'glance', by_ip=True )['admin'] }}
          glance_protocol: {{ salt['openstack_utils.service_urls']( 'glance', by_ip=True )['admin_protocol'] }}
          glance_api_insecure: {{ salt['pillar.get']( 'ssl_insecure', False ) }}
          scheduler_max_attempts: {{ salt['pillar.get']( 'nova:scheduler_max_attempts', 3 ) }}
        glance:
          host: "{{ openstack_parameters['controller_ip'] }}"
          api_insecure: {{ salt['pillar.get']( 'ssl_insecure', False ) }}
          api_servers: {{ salt['openstack_utils.service_urls']( 'glance', by_ip=True )['admin'] }}
          protocol: {{ salt['openstack_utils.service_urls']( 'glance', by_ip=True )['admin_protocol'] }}
        oslo_concurrency:
          lock_path: "{{ nova['files']['nova_tmp'] }}"
        keystone_authtoken: 
          insecure: {{ salt['pillar.get']( 'ssl_insecure', False ) }}
          auth_uri: {{ keystone_auth['public'] }}
          auth_url: {{ keystone_auth['auth_url'] }}
          auth_plugin: "password"
          project_domain_id: "default"
          user_domain_id: "default"
          project_name: "service"
          username: "nova"
          password: "{{ service_users['nova']['password'] }}"
        neutron:
          service_metadata_proxy: True
          metadata_proxy_shared_secret: {{ neutron['metadata_secret'] }}
          url: {{ salt['openstack_utils.service_urls']( 'neutron', by_ip=True )['public'] }}
          auth_strategy: keystone
          admin_auth_url: {{ salt['openstack_utils.service_urls']( 'keystone', by_ip=True )['admin'] }}/v2.0
          insecure: {{ salt['pillar.get']( 'ssl_insecure', False ) }}
          admin_tenant_name: service
          admin_username: neutron
          admin_password: "{{ service_users['neutron']['password'] }}"
    - require:
        - file: archive {{ nova['conf']['nova'] }} controller
{% for pkg in nova['packages']['controller'] %}
        - pkg: nova_controller_{{ pkg }}_install
{% endfor %}


nova_db_sync:
  cmd.run:
    - name: "su -s /bin/sh -c 'nova-manage db sync' nova"
    - require: 
      - ini: nova_controller_conf


nova_controller_sqlite_delete:
  file.absent:
    - name: {{ nova['files']['sqlite'] }}
    - require:
      - cmd: nova_db_sync

{% for service in nova['services']['controller'] %}
nova_controller_{{ service }}_running:
  service.running:
    - enable: True
    - name: "{{ nova['services']['controller'][service] }}"
    - require:
      - cmd: nova_db_sync
      - ini: nova_rabbitmq_conf
      - ini: nova_controller_conf
    - watch:
      - ini: nova_controller_conf
      - ini: nova_rabbitmq_conf
      - file: push policy.json configuration
{% endfor %}


nova_controller_wait:
  cmd:
    - run
    - name: sleep 5
    - onchanges:
{% for service in nova['services']['controller'] %}
      - service: nova_controller_{{ service }}_running
{% endfor %}
