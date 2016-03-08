archive policy.json file:
  file.copy:
    - name: /etc/nova/policy.json.orig
    - source: /etc/nova/policy.json
    - unless: ls /etc/nova/policy.json.orig

push policy.json configuration:
  file.managed:
    - source: salt://openstack/nova/policy.json.jinja2
    - name: /etc/nova/policy.json
    - template: jinja
    - user: root
    - group: nova
    - mode: 640