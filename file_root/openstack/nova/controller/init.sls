{% set openstack_parameters = salt['openstack_utils.openstack_parameters']() %}


include:
  - openstack.nova.controller.packages
  - openstack.nova.controller.{{ grains['os'] }}.{{ openstack_parameters['series'] }}
