{% set openstack_parameters = salt['openstack_utils.openstack_parameters']() %}


include:
  - openstack.cinder.controller.packages
  - openstack.cinder.controller.{{ grains['os'] }}.{{ openstack_parameters['series'] }}
