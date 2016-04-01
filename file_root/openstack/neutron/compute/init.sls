{% set openstack_parameters = salt['openstack_utils.openstack_parameters']() %}


include:
  - openstack.neutron.compute.packages
  - openstack.neutron.compute.{{ grains['os'] }}.{{ openstack_parameters['series'] }}
