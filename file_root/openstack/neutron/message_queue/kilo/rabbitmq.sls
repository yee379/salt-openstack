{% set neutron = salt['openstack_utils.neutron']() %}
{% set rabbitmq = salt['openstack_utils.rabbitmq']() %}
{% set openstack_parameters = salt['openstack_utils.openstack_parameters']() %}

{% if rabbitmq['ssl_enable'] %}
include:
  - ssl
{% endif %}

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
          rabbit_port: {{ rabbitmq['service_port'] }}
          rabbit_use_ssl: {{ rabbitmq['ssl_enable'] }}
        {% if rabbitmq['ssl_enable'] %}
          # kombu_ssl_ca_certs: {{ rabbitmq['ssl_ca_path'] }}
          kombu_ssl_certfile: {{ rabbitmq['ssl_crt_path'] }}
          kombu_ssl_keyfile: {{ rabbitmq['ssl_key_path'] }}
    - require:
      - cmd: create ssl crt file
      - cmd: create ssl key file
        {% endif %}
