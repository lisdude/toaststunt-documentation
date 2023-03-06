This repository contains the [ToastStunt Programmers Manual](toaststunt-programmers-manual.md) as well as documentation for the functions in the [ToastStunt](https://github.com/lisdude/toaststunt) server.

## ToastStunt Programmers Manual

The [ToastStunt Programmers Manual](toaststunt-programmers-manual.md) is an update to the original LambdaMOO Programmer's Manual and the Stunt Programmer's Manual, which includes up-to-date information on everything ToastStunt offers.

## ToastStunt Help Files

ToastStunt modifies much of the core functionality from LambdaMOO. That means that the builtin helpfiles will be out of date. Copying `update_verb.moo` onto your MOO will allow you to download the most up to date help files.

### Installing and Updating Help Files

#### ToastStunt 2.5.13 and later
1. Paste [update_verb.moo](update_verb.moo) into your MOO.
2. Run `@update-toaststunt-help`

#### Porting to ToastStunt 2.5.12 and earlier
1. Run line one first: `@create $generic_help named ToastStunt Help Database:ToastStunt Help Database,Help Database,Database,Help,ToastStunt`
2. Replace `#123` with the actual object number of the object you just created.
3. Paste!

After porting the help file to your MOO, you can use the `help toaststunt` command for a brief summary.

