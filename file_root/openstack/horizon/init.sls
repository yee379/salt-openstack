{% set openstack_parameters = salt['openstack_utils.openstack_parameters']() %}


include:
  - openstack.horizon.packages
  - openstack.horizon.{{ grains['os'] }}

install redirect for web page:
  file.managed:
    - name: /var/www/html/index.html
    - source: salt://openstack/horizon/redirect.html
    - template: jinja
    - defaults:
      fqdn: openstack.slac.stanford.edu
      protocol: https
      endpoint: dashboard