include:
  - openstack.cinder.controller.CentOS.kilo
  
# add patch to git for insecure support
{% if grains['os'] == 'CentOS' %}
{% set cinderclient_quotas_file = "/usr/lib/python2.7/site-packages/cinder/api/contrib/quotas.py" %}

backup cinderclient quotas file:
  file.copy:
    - name: {{ cinderclient_quotas_file }}.orig
    - source: {{ cinderclient_quotas_file }}
    - unless: ls {{ cinderclient_quotas_file }}.orig

ensure cinderclient quotas is patched:
  pkg.installed:
    - name: patch
    
patch cinderclient quotas file:
  file.patch:
    - name: {{ cinderclient_quotas_file }}
    - source: salt://openstack/cinder/controller/CentOS/liberty/cinder-api-contrib-quotas_https.patch
    - dry_run_first: True
    - hash: md5=a60b7591cd114a27007ed112a88f0307
    - require:
      - file: backup cinderclient quotas file
      - pkg: ensure cinderclient quotas is patched
    - onlyif: rpm -q --quiet python-cinderclient-1.4.0-1.el7.noarch
    - watch_in:
      - service: cinder_controller_api_running
    
{% endif %}