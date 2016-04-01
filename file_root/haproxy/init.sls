# install and configure haproxy for ssl proxying of openstack services

# this state relies upon the services.sls pillar. for each service that is https enabled, then we should setup a haproxy listener that forwards to the backend service ports

ensure haproxy is installed:
  pkg.installed:
    {% for package in salt['pillar.get']('resources:haproxy:packages') %}
    - name: {{ package }}
    {% endfor %}

include:
  - ssl

{% set ssl = salt['openstack_utils.ssl_cert']() %}
haproxy configuration file:
  file.managed:
    - name: {{ salt['pillar.get']( 'resources:haproxy:conf:haproxy' ) }}
    - source: salt://haproxy/etc/haproxy.cfg
    - template: jinja
    - defaults:
        ssl_cert_path: {{ ssl['pem'] }}
        controllers:
          - {{ salt['pillar.get']( 'controller' ) }}
    - user: root
    - group: root
    - mode: 644
    - require:
      - file: ensure system openstack certs
    - watch:
      - file: ensure system openstack certs
    
ensure haproxy is running:
  service.running:
    - name: haproxy
    - requires:
      - pkg: ensure haproxy is installed
      - file: haproxy configuration file
    - watch:
      - file: haproxy configuration file