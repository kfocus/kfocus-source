#!/usr/bin/env python3

# Copyright (C) 2018-2023 Simon Quigley <tsimonq2@ubuntu.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

import json
import libcalamares
from time import strftime
import urllib.request
from urllib.error import HTTPError, URLError
import socket
import logging
import distro
import xml.etree.ElementTree as ET
from os import remove


SUBDOMAINS_BY_COUNTRY_CODE = {
    "US": "us.", "AU": "au.", "SE": "no.", "NO": "no.",
    "NZ": "nz.", "NL": "nl.", "KR": "kr.", "DE": "de.",
    "GE": "ge.", "PF": "pf.", "CZ": "cz.", "HR": "hr."
}


def get_sources_template():
    return """# Automatically generated by Calamares on {date}.
# See http://help.ubuntu.com/community/UpgradeNotes for how to upgrade to
# newer versions of {distro}.
## Ubuntu distribution repository
##
## The following settings can be adjusted to configure which packages to use from Ubuntu.
## Mirror your choices (except for URIs and Suites) in the security section below to
## ensure timely security updates.
##
## Types: Append deb-src to enable the fetching of source package.
## URIs: A URL to the repository (you may add multiple URLs)
## Suites: The following additional suites can be configured
##   <name>-updates   - Major bug fix updates produced after the final release of the
##                      distribution.
##   <name>-backports - software from this repository may not have been tested as
##                      extensively as that contained in the main release, although it includes
##                      newer versions of some applications which may provide useful features.
##                      Also, please note that software in backports WILL NOT receive any review
##                      or updates from the Ubuntu security team.
## Components: Aside from main, the following components can be added to the list
##   restricted  - Software that may not be under a free license, or protected by patents.
##   universe    - Community maintained packages.
##                 Software from this repository is only maintained and supported by Canonical
##                 for machines with Ubuntu Pro subscriptions. Without Ubuntu Pro, the Ubuntu
##                 community provides best-effort security maintenance.
##   multiverse  - Community maintained of restricted. Software from this repository is
##                 ENTIRELY UNSUPPORTED by the Ubuntu team, and may not be under a free
##                 licence. Please satisfy yourself as to your rights to use the software.
##                 Also, please note that software in multiverse WILL NOT receive any
##                 review or updates from the Ubuntu security team.
##
## See the sources.list(5) manual page for further settings.
Types: deb
URIs: {url}
Suites: {codename} {codename}-updates {codename}-backports
Components: main universe restricted multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

## Ubuntu security updates. Aside from URIs and Suites,
## this should mirror your choices in the previous section.
Types: deb
URIs: http://security.ubuntu.com/ubuntu/
Suites: {codename}-security
Components: main universe restricted multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
"""


def get_country_code():
    if not libcalamares.globalstorage.value("hasInternet"):
        return ""
    
    geoip_config = libcalamares.job.configuration["geoip"]
    
    try:
        with urllib.request.urlopen(geoip_config["url"], timeout=75) as resp:
            if geoip_config["style"] == "json":
                return json.loads(resp.read().decode())["country_code"]
            elif geoip_config["style"] == "xml":
                return ET.parse(resp).getroot().find("CountryCode").text
    except (HTTPError, URLError, socket.timeout):
        logging.error("Failed to get country code.")
    return ""


def get_subdomain_by_country(country_code):
    return SUBDOMAINS_BY_COUNTRY_CODE.get(country_code, "")


def write_file(path, content):
    with open(path, "w") as f:
        f.write(content)


def run():
    country_code = get_country_code()
    subdomain = get_subdomain_by_country(country_code)
    base_url = "http://{}{}/ubuntu".format(subdomain, libcalamares.job.configuration["baseUrl"])
    codename = distro.codename()

    root_mount_point = libcalamares.globalstorage.value("rootMountPoint")

    sources = get_sources_template().format(date=strftime("%Y-%m-%d"), distro=libcalamares.job.configuration["distribution"], url=base_url, codename=codename)
    write_file(f"{root_mount_point}/etc/apt/sources.list.d/ubuntu.sources", sources)
    
    remove(f"{root_mount_point}/etc/apt/sources.list")

    libcalamares.globalstorage.insert("mirrorURL", base_url)
    libcalamares.globalstorage.insert("ubuntuCodename", codename)
