{% set openstack_parameters = salt['openstack_utils.openstack_parameters']() %}


include:
  - openstack.nova.compute.packages
  - openstack.nova.compute.{{ grains['os'] }}.{{ openstack_parameters['series'] }}.kvm
