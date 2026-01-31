
# Infrastructure

- [X] Seperate License Manager App for Custom Locking
- [X] Fix TPM problem on Linux if not sudo. Fails to waitForTerminationRequest
- [ ] Fix BOOST log coloring

# System State

## Windows
- [ ] Detect Docker
- [ ] Detect Virtualization
## Linux
- [X] Detect Docker
- [ ] Detect Virtualization
- lscpu | grep -w  'Hypervisor\|Virtualization'
* https://github.com/chuckleb/virt-what/blob/master/virt-what.in
* https://github.com/basedpill/detectvm/blob/main/src/antivm.hpp
* https://stackoverflow.com/questions/51911300/c-convenient-way-to-check-if-system-is-a-virtual-machine
* https://github.com/nemequ/portable-snippets/tree/master/cpu
* https://stackoverflow.com/questions/3668804/detecting-vmm-on-linux
* https://learn.microsoft.com/en-us/cpp/intrinsics/cpuid-cpuidex?view=msvc-170
* https://kb.vmware.com/s/article/1009458
# Fingerprint 
## Windows 
- [X] Hostname
- [X] MacAddress 
- [X] UUID 
- [X] DiskSerial
- [X] CPUID

## Linux
- [X] Hostname
- [X] MacAddress
- [X] UUID 
- [ ] DiskSerial 
- [X] CPUID 

# Docker
- [ ] Detect Persistence Move