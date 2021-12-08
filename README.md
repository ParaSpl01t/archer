# archer

Arch + minimal GNOME installation script + few more packages.

## Usage

### Prepration

-   Connect to internet using ethernet or `iwctl` command. [iwd reference](https://wiki.archlinux.org/title/Iwd#Usage)
-   Update mirrors using `reflector`. [reflector reference](https://wiki.archlinux.org/title/reflector#Usage)
-   [Partition](https://wiki.archlinux.org/title/installation_guide#Partition_the_disks) and format the hard disk (_only BIOS with MBR is supported_). You can use `cfdisk` for this.

### Download archer

```sh
curl -LO git.io/archer
bash archer
```

## IMPORTANT

-   Do not exit the script in the middle of execution. Resuming is not supported.
-   Every step is final and cannot be restarted.
-   It's recommended to reformat the partition if you want to restart the installation.

## TODO

-   Add installation resume support.
-   Add better handling of script execution. (current is linear and non-repeatable)
-   Add option to select other locales apart from en_US.utf-8
-   Add UEFI/GPT support
-   Support more minimal DEs?
-   More packages
-   Better package catagories and minimal default selection
-   Option to add more than one user.
