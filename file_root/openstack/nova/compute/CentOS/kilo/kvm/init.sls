{% set nova = salt['openstack_utils.nova']() %}
{% set service_users = salt['openstack_utils.openstack_users']('service') %}
{% set openstack_parameters = salt['openstack_utils.openstack_parameters']() %}
{% set keystone_auth = salt['openstack_utils.keystone_auth']( by_ip=True ) %}

archive {{ nova['conf']['nova'] }} compute:
  file.copy:
    - name: {{ nova['conf']['nova'] }}.orig
    - source: {{ nova['conf']['nova'] }} 
    - unless: ls {{ nova['conf']['nova'] }}.orig

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
          # enabled_apis: osapi_compute, metadata
          debug: "{{ salt['openstack_utils.boolean_value'](openstack_parameters['debug_mode']) }}"
          verbose: "{{ salt['openstack_utils.boolean_value'](openstack_parameters['debug_mode']) }}"
          network_api_class: nova.network.neutronv2.api.API
          security_group_api: neutron
          linuxnet_interface_driver: nova.network.linux_net.LinuxOVSInterfaceDriver
          firewall_driver: nova.virt.firewall.NoopFirewallDriver
        keystone_authtoken:
          insecure: {{ salt['pillar.get']( 'ssl_insecure', False ) }}
          auth_uri: {{ keystone_auth['public'] }}
          auth_url: {{ keystone_auth['admin'] }}
          auth_plugin: "password"
          project_domain_id: "default"
          user_domain_id: "default"
          project_name: "service"
          username: "nova"
          password: "{{ service_users['nova']['password'] }}"
        glance:
          api_insecure: {{ salt['pillar.get']( 'ssl_insecure', False ) }}
          host: "{{ openstack_parameters['controller_ip'] }}"
          protocol: {{ salt['openstack_utils.service_urls']( 'glance', by_ip=True )['public_protocol'] }}
          api_servers: {{ salt['openstack_utils.service_urls']( 'glance', by_ip=True )['public'] }}
        oslo_concurrency:
          lock_path: "{{ nova['files']['nova_tmp'] }}"
        neutron:
          insecure: {{ salt['pillar.get']( 'ssl_insecure', False ) }}
          url: {{ salt['openstack_utils.service_urls']( 'neutron', by_ip=True )['public'] }}
          auth_strategy: keystone
          admin_auth_url: {{ salt['openstack_utils.service_urls']( 'keystone', by_ip=True )['admin_with_version'] }}
          admin_tenant_name: service
          admin_username: neutron
          admin_password: "{{ service_users['neutron']['password'] }}"
        libvirt:
          virt_type: {{ nova['libvirt_virt_type'] }}
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
      - ini: nova_compute_conf
    - watch:
      - ini: nova_compute_conf
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
    - require:
{% for service in nova['services']['compute']['kvm'] %}
      - service: nova_compute_{{ service }}_running
{% endfor %}
