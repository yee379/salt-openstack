ensure nginx is installed:
  pkg.installed:
    - name: nginx

include:
  - ssl
  
{% set dhparam_file = salt['pillar.get']( 'resources:nginx:conf:dhparam' ) %}
dhparam for nginx:
  cmd.run:
    - name: openssl dhparam -out {{ dhparam_file }} 4096
    - unless: test -e {{ dhparam_file }}
    
{% set ssl_cert_path = salt['openstack_utils.ssl_cert']() %}
nginx configuration file:
  file.managed:
    - name: {{ salt['pillar.get']( 'resources:nginx:conf:nginx' ) }}
    - source: salt://nginx/nginx.conf.jinja2
    - template: jinja
    - defaults:
        ssl_cert_path: {{ ssl_cert_path }}
        dhparam: {{ dhparam_file }}
        controllers:
          - {{ salt['pillar.get']( 'controller' ) }}
    - user: root
    - group: root
    - mode: 644
    
ensure nginx is running:
  service.running:
    - name: nginx
    - requires:
      - pkg: ensure nginx is installed
      - file: nginx configuration file
    - watch:
      - file: nginx configuration file