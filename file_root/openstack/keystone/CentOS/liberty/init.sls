include:
  - openstack.keystone.CentOS.kilo

ensure keystone paste configuration:
  file.managed:
    - name: /etc/keystone/keystone-paste.ini
    - source: salt://openstack/keystone/{{ grains['os'] }}/liberty/keystone-paste.ini
    - user: keystone
    - group: keystone
    - mode: 640
    - require_in:
      service: keystone_service_httpd_running