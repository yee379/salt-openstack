{% set neutron = salt['openstack_utils.neutron'](grains['id']) %}


{% for pkg in neutron['packages']['compute']['kvm'] %}
neutron_compute_{{ pkg }}_install:
  pkg.installed:
    - name: {{ pkg }}
{% endfor %}
