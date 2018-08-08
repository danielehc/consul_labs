#!/usr/bin/env bash

pkg="wget"

for p in ${pkg} ; do echo "describe package('${p}') do
  it { should be_installed }
end
"
done
