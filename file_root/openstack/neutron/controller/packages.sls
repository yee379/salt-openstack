{% set neutron = salt['openstack_utils.neutron'](grains['id']) %}


{% for pkg in neutron['packages']['controller'] %}
neutron_controller_{{ pkg }}_install:
  pkg.installed:
    - name: {{ pkg }}
{% endfor %}
