#!/bin/env python

from keystoneclient.auth.identity import v2
from keystoneclient import session
import keystoneclient.v2_0.client as ksclient
import novaclient.v2.client as nvclient
# import glanceclient.v2.client as glclient

from time import time
from dateutil import parser as dateparser
import ast
from sys import argv, exit
import os
import logging
import argparse

from pprint import pformat
from urllib2 import urlopen



def send_to_influxdb( data, server='influxdb01.slac.stanford.edu:8086', db='openstack', user='osmaint', password='osmaint', dry_run=False ):
    c = 'http://%s/write?db=%s&u=%s&p=%s&precision=%s' % ( server, db, user, password, 's')
    if not dry_run:
        # logging.debug("C: %s" % (c,))
        # logging.debug("%s" % '\n'.join(data) )
        try:
            resp = urlopen( c, '\n'.join(data) )
            code = resp.getcode()
            if not code == 204:
                raise Exception( code )
        except Exception, e:
            logging.error("ERROR: %s" % (e,))
            return 1
    else:
        print '\n'.join( data )

    return 0

def pformat_line_protocol( database, meta, data, time ):
    m = []
    for k in sorted( meta.keys() ):
        m.append( '%s=%s' % (k,meta[k]) )
    d = []
    for k in sorted( data.keys() ):
        d.append( '%s=%s' % (k,data[k]) )
    return '%s,%s %s %s' % (database,','.join(m),','.join(d), time )
    
class EnvDefault(argparse.Action):
    def __init__(self, envvar, required=True, default=None, **kwargs):
        if not default and envvar:
            if envvar in os.environ:
                default = os.environ[envvar]
        if required and default:
            required = False
        super(EnvDefault, self).__init__(default=default, required=required, 
                                         **kwargs)

    def __call__(self, parser, namespace, values, option_string=None):
        setattr(namespace, self.dest, values)

        
def hosts_by_aggregate(nova_client, hypervisors):
    hba = {}
    for aggregate in nova_client.aggregates.list():
        hba[aggregate.name] = []
        for hypervisor in aggregate.hosts:
            try:
                hba[aggregate.name].append(hypervisors[hypervisor])
            except exceptions.NotFound as e:
                logging.error("Cannot find %s hypervisor: %s" %
                            (hypervisor, e))
            except Exception as e:
                logging.error("Problem retrieving hypervisor: %s" % e)
    return hba

def host_aggregate_statistics( nova_client, hypervisors, vcpu_multiplier=1, memory_multiplier=1 ):
    aggregates = {}
    for aggregate, hosts in hosts_by_aggregate( nova_client, hypervisors ).iteritems():
        aggregates[aggregate] = {
            'disk': [0, 0, 0, 0],
            'vcpus': dict.fromkeys(['total',
                                    'used',
                                    'real'], 0),
            'instances': 0,
            'memory': dict.fromkeys(['total',
                                     'used',
                                     'free'], 0),
            'servers': [len(hosts), 0]
        }
        for host in hosts:
            aggregates[aggregate] = {
                'instances': aggregates[aggregate]['instances'] + host.running_vms,
                'disk': [x[0] + x[1] for x in zip(
                    aggregates[aggregate]['disk'], [
                        host.local_gb,
                        host.local_gb_used,
                        host.free_disk_gb,
                        host.disk_available_least,
                    ]
                )],
                'memory': {
                    'total': aggregates[aggregate]['memory']['total'] + host.memory_mb * memory_multiplier,
                    'real': aggregates[aggregate]['memory']['total'] + host.memory_mb,
                    'used': (aggregates[aggregate]['memory']['total']
                             + host.memory_mb * memory_multiplier
                             - aggregates[aggregate]['memory']['used']
                             + host.memory_mb_used),
                    'used_real':  aggregates[aggregate]['memory']['used'] + host.memory_mb_used,
                    'free':  aggregates[aggregate]['memory']['free'] + host.free_ram_mb,
                },
                'vcpus': {
                    'total': aggregates[aggregate]['vcpus']['total'] + host.vcpus * vcpu_multiplier,
                    'real': aggregates[aggregate]['vcpus']['real'] + host.vcpus,
                    'used': aggregates[aggregate]['vcpus']['used'] + host.vcpus_used,
                },
                'servers': [x[0] + x[1] for x in zip(
                    aggregates[aggregate]['servers'],
                    [0, host.current_workload])]
            }

        if aggregates[aggregate]['servers'][0] > 0:
            aggregates[aggregate]['servers'][1] = \
                aggregates[aggregate]['servers'][1] // \
                aggregates[aggregate]['servers'][0]

    return aggregates
    


if __name__ == '__main__':

    parser = argparse.ArgumentParser(description='upload openstack statistics to influxdb using client libraries')
    parser.add_argument( '--username', help="openstack username", action=EnvDefault, envvar='OS_USERNAME' )
    parser.add_argument( '--password', help="openstack password", action=EnvDefault, envvar='OS_PASSWORD' )
    parser.add_argument( '--auth_url', help="auth url", action=EnvDefault, envvar='OS_AUTH_URL' )
    parser.add_argument( '--tenant_name', help="openstack tenant name", action=EnvDefault, envvar='OS_TENANT_NAME' )
    parser.add_argument( '--dry_run', help="do not send data", default=False, action='store_true' )
    parser.add_argument( '--verbose', help="verbose", default=False, action='store_true' )
    parser.add_argument( '--insecure', help="ignore ssl certs", default=False, action='store_true' )


    opts = vars(parser.parse_args(argv[1:]))

    if os.path.isfile( opts['password'] ):
        with open( opts['password'] ) as f:
            opts['password'] = f.readlines().pop(0).strip()

    # get authn
    auth = v2.Password( username=opts['username'], password=opts['password'], auth_url=opts['auth_url'], tenant_name=opts['tenant_name'] )
    sess = session.Session( auth=auth, verify=not opts['insecure'] )
    keystone = ksclient.Client( session=sess, verify=False, insecure=opts['insecure'] )

    # get list of tenants
    tenants = {}
    for t in keystone.tenants.list():
        logging.debug("found tenant: %s" % (t.to_dict(),))
        tenants[t.id] = t.name

    # get list of users
    users = {}
    for u in keystone.users.list():
        logging.debug("found user: %s" % (u.to_dict(),))
        users[u.id] = u.username

    # TODO: get list of images
    images = {}
    #glance_endpoint = keystone.service_catalog.url_for(service_type='image', endpoint_type='publicURL')
    #glance = glclient.Client( session=sess )

    #for i in glance.images.list():
    #    logging.debug("g: %s" % (i.to_dict(),))

    # get nova client
    nova = nvclient.Client( session=keystone.session, insecure=True )

    # get list of flavours
    flavours = {}
    for f in nova.flavors.list( is_public=None ):
        logging.debug("found flavour: %s" % (f.to_dict(),))
        flavours[f.id] = f

    now = int(time())
    cache = []

    for h in nova.hypervisors.list( detailed=True ):
       logging.debug("h: %s " % (h.to_dict(),) )
    servers = {}
    for s in nova.servers.list( search_opts={'all_tenants': 1}, detailed=True ):
        d = s.to_dict()
        logging.debug( "found server: %s" % (d,) )
        f = flavours[d['flavor']['id']].to_dict()
        logging.debug( '  %s' % d['image'] )
        logging.debug( '  %s' % d['OS-EXT-STS:power_state'] )
        meta = {
            'host': d['name'].replace(' ', '_'),
            'hypervisor': d['OS-EXT-SRV-ATTR:hypervisor_hostname'],
            'image': f['name'],
            'tentant': tenants[d['tenant_id']],
            'user': users[d['user_id']]
        }
        data = {
            'disk': f['disk'] + f['OS-FLV-EXT-DATA:ephemeral'],
            'ram': f['ram'],
            'status': '"%s"' % d['status'],
            'vcpus': f['vcpus']
        }
        cache.append( pformat_line_protocol( 'instances', meta, data, now ) )

    # hypervisor statistics
    # cache list of hypervisors
    hypervisors = {}
    for hypervisor in nova.hypervisors.list():
        hypervisors[hypervisor.service['host']] = hypervisor
    for host_aggregate, data in hosts_by_aggregate( nova, hypervisors ).iteritems():
        logging.debug( "HBA: %s" % (host_aggregate,))
        for this in data:
            logging.debug("  %s" % pformat(this.__dict__,))
            cpu = ast.literal_eval(this.cpu_info)
            meta = {
                'cores': cpu['topology']['cores'],
                'host': this.hypervisor_hostname,
                'host_aggregate': host_aggregate,
                'model': cpu['model'],
                'sockets': cpu['topology']['sockets'],
                'threads': cpu['topology']['threads'],
                'type': this.hypervisor_type,
                'vendor': cpu['vendor'],
                'version': this.hypervisor_version,
            }
            data = {}
            for key in ( 'current_workload', 'disk_available_least', 'free_disk_gb', 'free_ram_mb', 'local_gb', 'local_gb_used', 'memory_mb', 'memory_mb_used', 'running_vms', 'state', 'status', 'vcpus', 'vcpus_used' ):
                value = getattr( this, key )
                if key in ( 'status', 'state', ):
                    value = '"%s"' % value
                data[key] = value
            cache.append( pformat_line_protocol( 'hypervisor', meta, data, now ) )


    # # summary of all hypervisors
    stats = nova.hypervisors.statistics()._info
    logging.debug( "HYP: \t %s" % (stats,))
    meta = {
        'auth_url': opts['auth_url']
    }
    data = {}
    for key in ( 'count', 'vcpus_used', 'local_gb_used', 'memory_mb', 'current_workload', 'vcpus', 'running_vms', 'free_disk_gb', 'disk_available_least', 'local_gb', 'free_ram_mb', 'memory_mb_used' ):
        data[key] = stats[key]
    cache.append( pformat_line_protocol( 'system', meta, data, now ) )

    # host agg
    agg = host_aggregate_statistics( nova, hypervisors )
    logging.debug( "AGG: \t %s" % (agg,))
    for aggregate, this in agg.iteritems():
        meta = {
            'name': aggregate,
        }
        data = {
            'hypervisors': this['servers'][0],
            'current_workload': this['servers'][1],
            'instances': this['instances'],
            'real_vcpus': this['vcpus']['real'],
            'total_vcpus': this['vcpus']['total'],
            'used_vcpus': this['vcpus']['used'],
            'memory_real': this['memory']['real'],
            'memory_total': this['memory']['total'],
            'memory_used_real': this['memory']['used_real'],
            'memory_free': this['memory']['free'],
            'memory_used': this['memory']['used'],
            'disk_local_gb': this['disk'][0],
            'disk_local_gb_used': this['disk'][1],
            'disk_free_disk_gb': this['disk'][2],
            'disk_available_least': this['disk'][3],
        }
        cache.append( pformat_line_protocol( 'host_aggregate', meta, data, now ) )

    # get services
    for instance in nova.services.list():
        logging.debug(" %s" % (instance.__dict__,) )
        meta = {
            'service': instance.binary,
            'host': instance.host,
            'zone': instance.zone
        }
        data = {
            'status': '"%s"' % instance.status,
            'state': '"%s"' %instance.state
        }
        epoch = dateparser.parse( instance.updated_at ).strftime('%s')
        cache.append( pformat_line_protocol( 'services', meta, data, epoch ) )

    ret = send_to_influxdb( cache, dry_run=opts['dry_run'] )

    exit( ret )
