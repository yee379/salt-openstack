

set cinder log file permissions:
  file.directory:
    - name: /var/log/cinder
    - group: cinder
    - unless: test ! -d /var/log/cinder
    
set heat log file permissions:
  file.directory:
    - name: /var/log/heat
    - group: heat
    - unless: test ! -d /var/log/heat

set nova log file permissions:
  file.directory:
    - name: /var/log/nova
    - group: nova

set logs permissions for splunk:
  user.present:
    - name: splunk
    - groups:
      - nova
      - neutron
    - optional_groups:
      - cinder
      - keystone
      - apache
      - glance
      - heat
    - require:
      - user: splunk_user
      