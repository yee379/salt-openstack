{% set neutron = salt['openstack_utils.neutron']() %}
{% set rabbitmq = salt['openstack_utils.rabbitmq']() %}
{% set openstack_parameters = salt['openstack_utils.openstack_parameters']() %}

archive {{ neutron['conf']['neutron'] }} rabbitmq:
  file.copy:
    - name: {{ neutron['conf']['neutron'] }}.orig
    - source: {{ neutron['conf']['neutron'] }}
    - unless: ls {{ neutron['conf']['neutron'] }}.orig

neutron_rabbitmq_conf:
  ini.options_present:
    - name: "{{ neutron['conf']['neutron'] }}"
    - sections:
        DEFAULT:
          rpc_backend: "rabbit"
        oslo_messaging_rabbit:
          rabbit_host: "{{ openstack_parameters['controller_ip'] }}"
          rabbit_userid: "{{ rabbitmq['user_name'] }}"
          rabbit_password: {{ rabbitmq['user_password'] }}
    - require:
      - file: archive {{ neutron['conf']['neutron'] }} rabbitmq