{% set heat = salt['openstack_utils.heat']() %}
{% set rabbitmq = salt['openstack_utils.rabbitmq']() %}
{% set openstack_parameters = salt['openstack_utils.openstack_parameters']() %}
    
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
          rabbit_port: {{ rabbitmq['service_port'] }}
          rabbit_use_ssl: {{ rabbitmq['ssl_enable'] }}
        {% if rabbitmq['ssl_enable'] %}
          # kombu_ssl_ca_certs: {{ rabbitmq['ssl_ca_path'] }}
          kombu_ssl_certfile: {{ rabbitmq['ssl_crt_path'] }}
          kombu_ssl_keyfile: {{ rabbitmq['ssl_key_path'] }}
        {% endif %}