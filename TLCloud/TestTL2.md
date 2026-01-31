
# Software Test
## cmake
### list test 
ctest -N
### run test filtered
sudo ctest -R "From"

## dotnet
### list tests
sudo dotnet test -t 
### run test filtered
sudo dotnet test  --filter FullyQualifiedName\!~IntegrationTests
