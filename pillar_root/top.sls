openstack: 
  "net-openstack01.slac.stanford.edu,net-pool01.slac.stanford.edu,net-pool02.slac.stanford.edu":
    - match: list
    - {{ grains['os'] }}
    - kilo.credentials
    - kilo.environment
    - kilo.networking

  # atlas
  "os-ctrl01.slac.stanford.edu":
    # - match: list
    - {{ grains['os'] }}
    - os-ctrl.credentials
    - os-ctrl.environment
    - os-ctrl.networking


  # atlas
  "os-ctrl02.slac.stanford.edu":
    - {{ grains['os'] }}
    - liberty.credentials
    - liberty.environment
    - liberty.networking


