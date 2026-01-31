```bash
aspirate generate  --output-format compose  --container-registry docker.io --container-repository-prefix mariobr


dotnet publish "D:\DEV\TrustedLicensing2\TLCloud\_dev\TLCloudHost\../VendorBoardAPI/VendorBoardAPI.csproj" -t:PublishContainer --verbosity "quiet" --nologo -r "linux-x64" -p:ContainerRepository="mariobr/VendorBoardAPI" -p:ContainerImageTag="latest"

dotnet publish "D:\DEV\TrustedLicensing2\TLCloud\_dev\TLCloudHost\../VendorBoardWeb/VendorBoardWeb/VendorBoardWeb.csproj" -t:PublishContainer --verbosity "quiet" --nologo -r "linux-x64" -p:ContainerRepository="mariobr/VendorBoardWeb" -p:ContainerImageTag="latest" -p:ErrorOnDuplicatePublishOutputFiles="false"

dotnet publish "D:\DEV\TrustedLicensing2\TLCloud\_dev\TLCloudHost\../VendorBoardAPI/VendorBoardAPI.csproj" -t:PublishContainer --verbosity "quiet" --nologo -r "linux-x64" -p:ContainerRegistry="docker.io"
-p:ContainerRepository="mariobr/VendorBoardAPI" -p:ContainerImageTag="latest"

dotnet publish "D:\DEV\TrustedLicensing2\TLCloud\_dev\TLCloudHost\../VendorBoardWeb/VendorBoardWeb/VendorBoardWeb.csproj" -t:PublishContainer --verbosity "quiet" --nologo -r
"linux-x64" -p:ContainerRegistry="docker.io" -p:ContainerRepository="mariobr/VendorBoardWeb" -p:ContainerImageTag="latest" -p:ErrorOnDuplicatePublishOutputFiles="false"

```