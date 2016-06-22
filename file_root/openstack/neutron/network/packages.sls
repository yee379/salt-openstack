{% set neutron = salt['openstack_utils.neutron'](grains['id']) %}


{% for pkg in neutron['packages']['network'] %}
neutron_network_{{ pkg }}_install:
  pkg.installed:
    - name: {{ pkg }}
{% endfor %}
