<p align="center">
<img src="https://pbui.codes/logo.png" width="25%">
<h1 align="center">pbui-main</h1>
</p>

![asciicast](https://chadpaste.com/f/qze.gif)


## What is the PBUI project?

The PBUI (POSIX-compliant BSD/Linux Userland Implementation) project is a a free and open source project intended 
to implement some standard library toolsets in the Zig programming language. We will also implement some basic applets 
and a shell to demonstrate usage of the toolsets as well as provide functionality. 

Another goal of the PBUI project is to help improve documentation for Zig through our blog posts, some of which
will take the form of tutorials that explain how to use both our toolsets and other Zig functions when creating 
applets. By doing this, we hope to make Zig more user friendly and encourage others to create Zig-based applications.

## Dependencies
Supported operating systems:
  - Linux kernel >= 5.4.23 (Validated for Ubuntu)
  - Zig 0.5.0+ab4ea5d3c
  
## Installation
After cloning the repository, run `zig build`.  The `pbui` executable will be located in `zig-cache/bin/pbui`.

## Usage
For a list of applets, run `./pbui` or `./pbui -h`.  Currently supported applets include:
  - `basename`
  - `dirname`
  - `false`
  - `head`
  - `ls`
  - `main`
  - `mkdir`
  - `rm`
  - `sleep`
  - `tail`
  - `true`
  - `wc`

To run a given applet, use: `./pbui [APPLET] [arguments]`.
  
