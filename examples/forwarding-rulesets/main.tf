module "naming" {
  source  = "codectl/naming/azure"
  version = "~> 0.1"

  suffix = ["demo", "dev"]
}

module "regions" {
  source  = "codectl/locations/azure"
  version = "~> 1.0"

  location = {
    primary = "germanywestcentral"
  }
}

module "rg" {
  source  = "codectl/rg/azure"
  version = "~> 1.0"

  groups = {
    demo = {
      name     = module.naming.resource_group.name_unique
      location = module.regions.location.primary.name
    }
  }
}

module "network" {
  source  = "codectl/vnet/azure"
  version = "~> 1.0"

  vnet = {
    name                = module.naming.virtual_network.name
    location            = module.rg.groups.demo.location
    resource_group_name = module.rg.groups.demo.name
    address_space       = ["10.19.0.0/16"]

    subnets = {
      inbound = {
        address_prefixes = ["10.19.99.0/27"]
        delegations = {
          dns = {
            name = "Microsoft.Network/dnsResolvers"
            actions = [
              "Microsoft.Network/virtualNetworks/subnets/join/action"
            ]
          }
        }
      }
      outbound = {
        address_prefixes = ["10.19.101.0/27"]
        delegations = {
          dns = {
            name = "Microsoft.Network/dnsResolvers"
            actions = [
              "Microsoft.Network/virtualNetworks/subnets/join/action"
            ]
          }
        }
      }
    }
  }
}

module "dnsresolver" {
  source  = "codectl/dnspr/azure"
  version = "~> 1.0"

  resolver = {
    name                = module.naming.private_dns_resolver.name
    location            = module.rg.groups.demo.location
    resource_group_name = module.rg.groups.demo.name
    virtual_network_id  = module.network.vnet.id

    inbound_endpoints = {
      ep1 = {
        ip_configurations = {
          config1 = {
            subnet_id = module.network.subnets.inbound.id
          }
        }
      }
    }
    outbound_endpoints = {
      ep1 = {
        subnet_id           = module.network.subnets.outbound.id
        forwarding_rulesets = local.forwarding_rulesets
      }
    }
  }
}
