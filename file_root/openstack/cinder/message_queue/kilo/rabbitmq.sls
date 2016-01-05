{% set cinder = salt['openstack_utils.cinder']() %}
{% set rabbitmq = salt['openstack_utils.rabbitmq']() %}
{% set openstack_parameters = salt['openstack_utils.openstack_parameters']() %}

archive {{ cinder['conf']['cinder'] }} rabbitmq:
  file.copy:
    - name: {{ cinder['conf']['cinder'] }}.orig
    - source: {{ cinder['conf']['cinder'] }}
    - unless: ls {{ cinder['conf']['cinder'] }}.orig

cinder_rabbitmq_conf:
  ini.options_present:
    - name: "{{ cinder['conf']['cinder'] }}"
    - sections:
        DEFAULT:
          rpc_backend: "rabbit"
        oslo_messaging_rabbit:
          rabbit_host: "{{ openstack_parameters['controller_ip'] }}"
          rabbit_userid: "{{ rabbitmq['user_name'] }}"
          rabbit_password: {{ rabbitmq['user_password'] }}
    - require:
      - file: archive {{ cinder['conf']['cinder'] }} rabbitmq
