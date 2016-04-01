{% set openstack_parameters = salt['openstack_utils.openstack_parameters']() %}


include:
  - openstack.neutron.controller.packages
  - openstack.neutron.controller.{{ grains['os'] }}.{{ openstack_parameters['series'] }}
