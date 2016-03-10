{% set glance = salt['openstack_utils.glance']() %}


{% for pkg in glance['packages'] %}
glance_{{ pkg }}_install:
  pkg.installed:
    - name: {{ pkg }}
{% endfor %}

{% set glanceclient_https_file = "/usr/lib/python2.7/site-packages/glanceclient/common/https.py" %}
{% if pillar.get('openstack_series') == 'kilo' and grains['os'] == 'CentOS' %}
# RDO kilo has a bad version of glanceclient, so need to patch with local file
backup glanceclient https file:
  file.copy:
    - name: {{glanceclient_https_file}}.orig
    - source: {{glanceclient_https_file}}
    - unless: ls {{glanceclient_https_file}}.orig

ensure patch package is installed:
  pkg.installed:
    - name: patch

patch glanceclient https file:
  file.patch:
    - name: {{glanceclient_https_file}}
    - source: salt://openstack/glance/{{ grains['os'] }}/{{ pillar.get('openstack_series') }}/glanceclient_https.patch
    - dry_run_first: True
    - hash: md5=f9d524d570d90ba4bf8acfe7067ae5d6
    - require:
      - file: backup glanceclient https file
      - pkg: ensure patch package is installed
{% endif %}

# TODO: hmmm.. .how do we propogate the fact that the file has been patched and that the service should be restarted?
# glance program files okay:
#   file.exists:
#     - name: {{ glanceclient_https_file }}
#     {% if pillar.get('openstack_series') == 'kilo' and grains['os'] == 'CentOS' %}
#     - onchanges:
#       - file: patch glanceclient https file
#     {% endif %}
