{% set heat = salt['openstack_utils.heat']() %}
{% set rabbitmq = salt['openstack_utils.rabbitmq']() %}
{% set openstack_parameters = salt['openstack_utils.openstack_parameters']() %}

archive {{ heat['conf']['heat'] }} rabbitmq:
  file.copy:
    - name: {{ heat['conf']['heat'] }}.orig
    - source: {{ heat['conf']['heat'] }}
    - unless: ls {{ heat['conf']['heat'] }}.orig
    
heat_rabbitmq_conf:
  ini.options_present:
    - name: "{{ heat['conf']['heat'] }}"
    - sections:
        DEFAULT:
          rpc_backend: "rabbit"
        oslo_messaging_rabbit:
          rabbit_host: "{{ openstack_parameters['controller_ip'] }}"
          rabbit_userid: "{{ rabbitmq['user_name'] }}"
          rabbit_password: {{ rabbitmq['user_password'] }}
    - require:
      - file: archive {{ heat['conf']['heat'] }} rabbitmq
