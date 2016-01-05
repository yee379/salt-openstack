{% set nova = salt['openstack_utils.nova']() %}
{% set rabbitmq = salt['openstack_utils.rabbitmq']() %}
{% set openstack_parameters = salt['openstack_utils.openstack_parameters']() %}

archive {{ nova['conf']['nova'] }} rabbitmq:
  file.copy:
    - name: {{ nova['conf']['nova'] }}.orig
    - source: {{ nova['conf']['nova'] }}
    - unless: ls {{ nova['conf']['nova'] }}.orig
    
nova_rabbitmq_conf:
  ini.options_present:
    - name: "{{ nova['conf']['nova'] }}"
    - sections:
        DEFAULT:
          rpc_backend: "rabbit"
        oslo_messaging_rabbit:
          rabbit_host: "{{ openstack_parameters['controller_ip'] }}"
          rabbit_userid: "{{ rabbitmq['user_name'] }}"
          rabbit_password: {{ rabbitmq['user_password'] }}
    - require:
      - file: archive {{ nova['conf']['nova'] }} rabbitmq