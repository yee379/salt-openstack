{% set nova = salt['openstack_utils.nova']( grains['id'] ) %}
{% set service_users = salt['openstack_utils.openstack_users']('service') %}
{% set openstack_parameters = salt['openstack_utils.openstack_parameters']() %}
{% set keystone_auth = salt['openstack_utils.keystone_auth']( by_ip=True ) %}
{% set neutron = salt['openstack_utils.neutron'](grains['id']) %}

enable live-migrate configuration:
  ini.options_present:
    - name: /etc/libvirt/libvirtd.conf
    - sections:
        DEFAULT_IMPLICIT:
          listen_tcp: '1'
          tcp_port: '"16509"'
          listen_addr: '"0.0.0.0"'
          listen_tls: '0'
          auth_tcp: '"none"'

enable live-migrate libvirtd listen:
  ini.options_present:
    - name: /etc/sysconfig/libvirtd
    - sections:
       DEFAULT_IMPLICIT:
         LIBVIRTD_ARGS: '"--listen"'

archive {{ nova['conf']['nova'] }} compute:
  file.copy:
    - name: {{ nova['conf']['nova'] }}.orig
    - source: {{ nova['conf']['nova'] }} 
    - unless: ls {{ nova['conf']['nova'] }}.orig

include:
  - openstack.nova.message_queue.{{ openstack_parameters['series'] }}.{{ openstack_parameters['message_queue'] }}
  - openstack.nova.policy_json
  
{% set minion_ip = salt['openstack_utils.minion_ip'](grains['id']) %}
nova_compute_conf:
  ini.options_present:
    - name: {{ nova['conf']['nova'] }}
    - sections:
        DEFAULT:
          auth_strategy: keystone
          my_ip: {{ minion_ip }}
          vnc_enabled: "True"
          vncserver_listen: {{ minion_ip }}
          novncproxy_port: {{ salt['pillar.get']('services:novnc:url:public:local_port', 6080 ) }}
          vncserver_proxyclient_address: {{ minion_ip }}
          novncproxy_base_url: {{ salt['openstack_utils.service_urls']( 'novnc', by_ip=False )['public_with_path'] }}
          # cpu_allocation_ratio: {{ nova['cpu_allocation_ratio'] }}
          # ram_allocation_ratio: {{ nova['ram_allocation_ratio'] }}
          # enabled_apis: osapi_compute, metadata
          debug: "{{ salt['openstack_utils.boolean_value'](openstack_parameters['debug_mode']) }}"
          verbose: "{{ salt['openstack_utils.boolean_value'](openstack_parameters['verbose_mode']) }}"
          network_api_class: nova.network.neutronv2.api.API
          security_group_api: neutron
          linuxnet_interface_driver: nova.network.linux_net.LinuxOVSInterfaceDriver
          firewall_driver: nova.virt.firewall.NoopFirewallDriver
          preallocate_images: {{ nova['preallocate_images'] }}
          network_device_mtu: {{ neutron['mtu'] }}
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
        glance:
          host: "{{ openstack_parameters['controller_ip'] }}"
          api_insecure: {{ salt['pillar.get']( 'ssl_insecure', False ) }}
          api_servers: {{ salt['openstack_utils.service_urls']( 'glance', by_ip=True )['public'] }}
          protocol: {{ salt['openstack_utils.service_urls']( 'glance', by_ip=True )['public_protocol'] }}
        oslo_concurrency:
          lock_path: "{{ nova['files']['nova_tmp'] }}"
        neutron:
          insecure: {{ salt['pillar.get']( 'ssl_insecure', False ) }}
          url: {{ salt['openstack_utils.service_urls']( 'neutron', by_ip=True )['public'] }}
          auth_strategy: keystone
          admin_auth_url: {{ salt['openstack_utils.service_urls']( 'keystone', by_ip=True )['admin'] }}/v2.0
          admin_tenant_name: service
          admin_username: neutron
          admin_password: "{{ service_users['neutron']['password'] }}"
        libvirt:
          virt_type: {{ nova['libvirt_virt_type'] }}
          block_migration_flag: VIR_MIGRATE_UNDEFINE_SOURCE, VIR_MIGRATE_PEER2PEER, VIR_MIGRATE_NON_SHARED_INC, VIR_MIGRATE_LIVE
          
    - require:
        - file: archive {{ nova['conf']['nova'] }} compute
{% for pkg in nova['packages']['compute']['kvm'] %}
        - pkg: nova_compute_{{ pkg }}_install
{% endfor %}

{% for service in nova['services']['compute']['kvm'] %}
nova_compute_{{ service }}_running:
  service.running:
    - enable: True
    - name: {{ nova['services']['compute']['kvm'][service] }}
    - require:
      - ini: nova_rabbitmq_conf
      - ini: nova_compute_conf
    - watch:
      - ini: nova_rabbitmq_conf
      - ini: nova_compute_conf
      - file: push policy.json configuration
      - ini: enable live-migrate configuration
      - ini: enable live-migrate libvirtd listen
{% endfor %}


nova_compute_sqlite_delete:
  file.absent:
    - name: {{ nova['files']['sqlite'] }}
    - require:
{% for service in nova['services']['compute']['kvm'] %}
      - service: nova_compute_{{ service }}_running
{% endfor %}


nova_compute_wait:
  cmd.run:
    - name: sleep 5
    - onchanges:
{% for service in nova['services']['compute']['kvm'] %}
      - service: nova_compute_{{ service }}_running
{% endfor %}
