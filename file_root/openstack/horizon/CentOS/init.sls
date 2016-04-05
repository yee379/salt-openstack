{% set horizon = salt['openstack_utils.horizon']() %}
{% set openstack_parameters = salt['openstack_utils.openstack_parameters']() %}
{% set keystone_auth = salt['openstack_utils.keystone_auth']( by_ip=True ) %}

horizon_local_settings:
  file.managed:
    - source: salt://openstack/horizon/local_settings.py
    - name: {{ horizon['conf']['local_settings'] }}
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - defaults:
        controller_ip: "{{ openstack_parameters['controller_ip'] }}"
        https: {{ salt['openstack_utils.horizon_https']() }}
        ssl_insecure: {{ salt['pillar.get']('ssl_insecure', False ) }}
        secret_key: {{ salt['pillar.get']('horizon:secret_key', salt['random.get_str']() ) }}
        keystone_url: {{ keystone_auth['public_with_version'] }}
        multidomain: False
        default_domain: Default
        debug: {{ salt['openstack_utils.boolean_value'](openstack_parameters['debug_mode']) }}
        api_result_limit: 1000
        api_result_page_size: 50
    - require:
{% for pkg in horizon['packages'] %}
      - pkg: horizon_{{ pkg }}_install
{% endfor %}


horizon_fix_permissions:
  file.directory:
    - name: {{ horizon['files']['openstack_dashboard_static'] }}
    - user: apache
    - group: apache
    - recurse:
        - user
        - group
    - require:
{% for pkg in horizon['packages'] %}
      - pkg: horizon_{{ pkg }}_install
{% endfor %}


horizon_setsebool_on:
  cmd.run:
    - name: setsebool -P httpd_can_network_connect on
    - unless: sestatus | egrep "SELinux\sstatus:\s*disabled"
    - require:
      - file: horizon_local_settings

{% if salt['pillar.get']('horizon:https',False) %}

include:
  - ssl

httpd mod ssl:
  pkg.installed:
    - name: mod_ssl

horizon httpd config:
  file.managed:
    - name: /etc/httpd/conf.d/openstack-dashboard.conf
    - backup: True
    - template: jinja
    - source: salt://openstack/horizon/{{ grains['os'] }}/openstack-dashboard.conf
    - require:
      - cmd: ensure system openstack certs
      - pkg: httpd mod ssl
    - watch:
      - cmd: ensure system openstack certs

{% endif %}

{% for service in horizon['services'] %}
horizon_{{ service }}_running:
  service.running:
    - enable: True
    - name: {{ horizon['services'][service] }}
    - watch: 
      - file: horizon_local_settings
  {% if salt['pillar.get']('horizon:https',False) %}
      - file: horizon httpd config
  {% endif %}
{% endfor %}
