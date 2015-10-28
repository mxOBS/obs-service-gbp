Name: obs-service-gbp
Version: 0.4
Release: 0
License: MIT
Group: Development/Tools/Building
Summary: OBS service using git-buildpackage
BuildArch: noarch
Source: %{name}-%{version}.tar.xz

Requires: git
Requires: git-buildpackage
Requires: dpkg

%description
This OBS service is meant to create debian source packages
from repositories compatible with git-buildpackage.

%prep
%setup -q

%install
install -v -m755 -d %{?buildroot}/usr/lib/obs/service
install -v -m755 gbp.sh %{?buildroot}/usr/lib/obs/service/gbp
install -v -m644 gbp.service %{?buildroot}/usr/lib/obs/service

%files
%dir /usr/lib/obs
%dir /usr/lib/obs/service
/usr/lib/obs/service/gbp
/usr/lib/obs/service/gbp.service
