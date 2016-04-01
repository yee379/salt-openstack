{% set openstack_parameters = salt['openstack_utils.openstack_parameters']() %}


include:
  - openstack.heat.packages
  - openstack.heat.{{ grains['os'] }}.{{ openstack_parameters['series'] }}
