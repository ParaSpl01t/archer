# archer
Arch + minimal GNOME installation script + few more packages.

## Usage
### Prepration
- Connect to internet using ethernet or `iwctl`
- Update mirrors using `reflector`.
- <a href="https://wiki.archlinux.org/title/installation_guide#Partition_the_disks" target="_blank">Partition</a> and format the hard disk (*only BIOS with MBR is supported*). You can use `cfdisk` for this.

```sh
curl -LO git.io/archer
chmod +x archer
./archer
```
