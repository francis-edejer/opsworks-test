file "/tmp/hello.txt" do
  content 'Welcome to Chef'
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end
