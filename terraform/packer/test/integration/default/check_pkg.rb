describe package('unzip') do
  it { should be_installed }
end

describe package('curl') do
  it { should be_installed }
end

describe package('jq') do
  it { should be_installed }
end

describe package('net-tools') do
  it { should be_installed }
end

describe package('dnsutils') do
  it { should be_installed }
end

describe package('psmisc') do
  it { should be_installed }
end

