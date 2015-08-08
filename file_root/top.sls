{% if pillar.get('openstack_series',False) %}
{% from "openstack/states.jinja" import minion_states with context %}

openstack:
  "*":
{% for state in minion_states %}
    - {{ state }}
{% endfor %}
{% endif %}