{% set rabbitmq = salt['openstack_utils.rabbitmq']() %}


{% for pkg in rabbitmq['packages'] %}
rabbitmq_{{ pkg }}_install:
  pkg.installed:
    - name: {{ pkg }}
{% endfor %}

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
