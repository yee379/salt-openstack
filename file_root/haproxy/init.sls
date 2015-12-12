# install and configure haproxy for ssl proxying of openstack services

# this state relies upon the services.sls pillar. for each service that is https enabled, then we should setup a haproxy listener that forwards to the backend service ports

ensure haproxy is installed:
  pkg.installed:
    - name: haproxy

{% set ssl_cert_path = salt['pillar.get']('haproxy:ssl_cert:dir') + salt['pillar.get']('haproxy:ssl_cert:file') %}
ensure openstack certs:
  cmd.run:
    - name: ./make-dummy-cert {{ ssl_cert_path }}
    - cwd: /etc/pki/tls/certs/
    - unless: test -e {{ ssl_cert_path }}

# jinja template haproxy config file for all services
haproxy configuration file:
  file.managed:
    - name: {{ salt['pillar.get']( 'resources:haproxy:conf:haproxy' ) }}
    - source: salt://haproxy/etc/haproxy.cfg
    - template: jinja
    - defaults:
        ssl_cert_path: {{ ssl_cert_path }}
        controllers:
          - {{ salt['pillar.get']( 'controller' ) }}
    - user: root
    - group: root
    - mode: 644
    
ensure haproxy is running:
  service.running:
    - name: haproxy
    - requires:
      - pkg: ensure haproxy is installed
      - file: haproxy configuration file
    - watch:
      - file: haproxy configuration file