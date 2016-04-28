{% set rabbitmq = salt['openstack_utils.rabbitmq']() %}


{% for pkg in rabbitmq['packages'] %}
rabbitmq_{{ pkg }}_install:
  pkg.installed:
    - name: {{ pkg }}
{% endfor %}

backup rabbitmq configuration:
  file.copy:
    - name: /etc/rabbitmq/rabbitmq.config.orig
    - source: /etc/rabbitmq/rabbitmq.config
    - unless: ls /etc/rabbitmq/rabbitmq.config.orig
  
include:
  - ssl

{% set ssl_enable = salt['pillar.get']( 'services:rabbitmq:url:internal:ssl', False ) %}
{% set ssl_cert_path = salt['openstack_utils.ssl_cert']() %}
rabbitmq configuration:
  file.managed:
    - source: salt://message_queue/rabbitmq/rabbitmq.config
    - name: /etc/rabbitmq/rabbitmq.config
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - defaults:
        port: {{ rabbitmq['port'] }}
        ssl_enable: {{ rabbitmq['ssl_enable'] }}
{% if rabbitmq['ssl_enable'] %}
        ssl_port: {{ rabbitmq['ssl_port'] }}
        # cacert_file: {{ rabbitmq['ssl_crt_path'] }}
        cert_file: {{ rabbitmq['ssl_crt_path'] }}
        key_file: {{ rabbitmq['ssl_key_path'] }}
        verify: verify_none
        fail_if_no_peer_cert: 'false'
{% else %}
{% endif %}
    - require:
      - file: backup rabbitmq configuration
{% if ssl_enable %}
      - file: ensure system openstack certs
{% endif %}
      
rabbitmq environment configurations:
  file.managed:
    - source: salt://message_queue/rabbitmq/rabbitmq-env.conf
    - name: /etc/rabbitmq/rabbitmq-env.conf
    - user: root
    - group: root
    - mode: 644

{% for service in rabbitmq['services'] %}
rabbitmq_{{ service }}_running:
  service.running:
    - enable: True
    - name: {{ rabbitmq['services'][service] }}
    - require:
  {% for pkg in rabbitmq['packages'] %}
      - pkg: rabbitmq_{{ pkg }}_install
  {% endfor %}
      - file: rabbitmq configuration
      - file: rabbitmq environment configurations
    - watch:
      - file: rabbitmq configuration
      - file: rabbitmq environment configurations
{% endfor %}


rabbitmq_openstack_user_create:
  cmd.run:
    - name: rabbitmqctl add_user {{ rabbitmq['user_name'] }} {{ rabbitmq['user_password'] }}
    - unless: rabbitmqctl list_users | awk '{if(NR>1){print $1}}' | grep {{ rabbitmq['user_name'] }}
    - require:
{% for service in rabbitmq['services'] %}
      - service: rabbitmq_{{ service }}_running
{% endfor %}


rabbitmq_openstack_user_permissions_set:
  cmd.run:
    - name: 'rabbitmqctl set_permissions {{ rabbitmq['user_name'] }} ".*" ".*" ".*"'
    - require:
      - cmd: rabbitmq_openstack_user_create
    - unless: rabbitmqctl list_user_permissions openstack | head -n -1 | tail -n -1 | awk '{if ( $2 == ".*" && $3 == ".*" && $4 == ".*" ){ exit 0 } else { exit 1 } }'
