#!/usr/bin/env bash

pkg="unzip curl jq net-tools dnsutils psmisc"

for p in ${pkg} ; do echo "describe package('${p}') do
  it { should be_installed }
end
"
done
