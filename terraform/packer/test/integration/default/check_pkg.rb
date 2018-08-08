describe package('wget') do
  it { should be_installed }
end

describe package('python-pip') do
  it { should be_installed }
end

describe package('python3-pip') do
  it { should be_installed }
end
