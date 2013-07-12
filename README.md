# vagrant-pristine

Restore your vagrant machines to a pristine state with a single command. Basically
the same as runnning a `vagrant destroy && vagrant up`.

## Installation

Make sure you have Vagrant 1.2+ and run:

```
vagrant plugin install vagrant-pristine
```

## Usage

```
Usage: vagrant pristine [vm-name]

    -f, --force                      Destroy without confirmation.
        --[no-]parallel              Enable or disable parallelism if provider supports it.
        --provider provider          Back the machine with a specific provider.
    -h, --help                       Print this help
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
