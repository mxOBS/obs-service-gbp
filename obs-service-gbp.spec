Name: obs-service-gbp
Version: 0.9
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
make DESTDIR=%{?buildroot} install

%files
%dir /usr/lib/obs
%dir /usr/lib/obs/service
/usr/lib/obs/service/gbp
/usr/lib/obs/service/gbp.service
