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

Ermir is a cli gem, it comes with 2 cli files `ermir` and `gadgetmarshal`, `ermir` is the actual gem and the latter is just a pretty interface to [GadgetMarshaller.java](https://github.com/hakivvi/ermir/blob/main/helpers/gadgetmarshaller/GadgetMarshaller.java) file which rewrites the gadgets of [Ysoserial](https://github.com/frohoff/ysoserial) to match `MarshalInputStream` requirements, the output should be then piped into `ermir` or a file, in case of custom gadgets use `MarshalOutputStream` instead of `ObjectOutputStream` to write your serialized object to the output stream.

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

## How does it work?
`java.rmi.registry.Registry` offers 5 methods: `list()`, `lookup()`, `bind()`, `rebind()`, `unbind()`:
- `public Remote lookup(String name)`: lookup() searches for a bound object in the registry by its name, the registry returns a `Remote` object which references the remote object that was looked up, the returned object is read using [`MarshalInputStream.readObject()`](http://hg.openjdk.java.net/jdk8u/jdk8u/jdk/file/jdk8u232-ga/src/share/classes/sun/rmi/registry/RegistryImpl_Stub.java#l127) which is just another layer on top of `ObjectInputStream`, basically it excpects after each class/proxy descriptor (`TC_CLASSDESC`/`TC_PROXYCLASSDESC`) an URL that will be used to load this class or proxy class. this is the same wild bug that was fixed in [jdk7u21](https://docs.oracle.com/javase/7/docs/technotes/guides/rmi/enhancements-7.html). (Ermir does not specify this URL as only old Java version are vulnerable, instead it just write [null](https://github.com/hakivvi/ermir/blob/240880237eb3a565daf1f5d79be19ac1d21cb4c8/helpers/gadgetmarshaller/GadgetMarshaller.java#L54)). as [Ysoserial](https://github.com/frohoff/ysoserial) gadgets are being serialized using `ObjectOutputStream`, Ermir uses `gadgetmarshal` -a wrapper around [GadgetMarshaller.java](https://github.com/hakivvi/ermir/blob/main/helpers/gadgetmarshaller/GadgetMarshaller.java)- to serialize the specified gagdet to match `MarshalInputStream` requirements.
![image](https://user-images.githubusercontent.com/67718634/173961275-4702c692-412c-4fe1-b593-ab2a26b9bd07.png)

- `public String[] list()`: list() asks the registry for all the bound objects names, while `String` type cannot be subsitued with a malicious gadget as it is not like any ordinary object and it is not read using `readObject()` but rather `readUTF()`, however as `list()` returns `String[]` which is an actual object and it is read using [`readObject()`](http://hg.openjdk.java.net/jdk8u/jdk8u/jdk/file/jdk8u232-ga/src/share/classes/sun/rmi/registry/RegistryImpl_Stub.java#l95), Ermir sends the gadget instead of this `String[]` type.
![image](https://user-images.githubusercontent.com/67718634/173961470-9b0092e4-afbe-4710-8a68-60851e59bb54.png)

- `public void bind(java.lang.String $param_String_1, java.rmi.Remote $param_Remote_2)`: bind() binds an object to a name on the registry, in bind() case the return type is `void` and there is nothing being returned, however if the registry specifies in the RMI return data packet that this return is an execptional return, the client/server client will call [`readObject()`](https://hg.openjdk.java.net/jdk8u/jdk8u/jdk/file/tip/src/share/classes/sun/rmi/transport/StreamRemoteCall.java#l270) despite the return type is `void`, this is how the regitry sends exceptions to its client (usually `java.lang.ClassNotFoundException`), once again Ermir will deliver the serialized gadget instead of a legitimate Exception object.
![image](https://user-images.githubusercontent.com/67718634/173962145-333228cc-82a1-46d6-aaa6-8cb4af8e178e.png)

- `public void rebind(java.lang.String $param_String_1, java.rmi.Remote $param_Remote_2)`: rebind() replaces the binding of the passed name with the supplied remote reference, also returns `void`, Ermir returns an exception just like bind().
- `public void unbind(java.lang.String $param_String_1)`: unbind() unbinds a remote object by name in the RMI registry, this one also returns `void`.

## PoC
![ermir](https://user-images.githubusercontent.com/67718634/173956672-17e73fb9-87af-4ef1-97ef-5f22377e2034.gif)

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/hakivvi/ermir. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/hakivvi/ermir/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Ermir project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/hakivvi/ermir/blob/main/CODE_OF_CONDUCT.md).
