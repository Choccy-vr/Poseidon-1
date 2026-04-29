# Poseidon 1 

![Build Image](https://github.com/Choccy-vr/Poseidon-1/blob/main/Media/Build.jpg)

Poseidon 1 is an upgraded display for the outdated and useless stock display on the Neptune 4 series of printers.

Used for easy print management, temperature control, move controls, printing status, files, and much more. inspired by more modern printer user interfaces, such as Bambu Lab's Display and Klipper Screen. The UI is built on top of the Material 3 Expressive design language with a light blue seed color to match the [project](https://github.com/OpenNeptune3D/OpenNept4une), which kinda pairs with. 

## Table of Contents
- [Why this exists](#why-this-exists)
- [Features](#features)
- [Showcase](#showcase)
- [Description](#description)
- [Hardware Specifications](#hardware-specifications)

## Why this exists

A little while ago, I started a project to fix the basic UI issues in the Neptune 4 series of printers. You can find it [here](https://github.com/OpenNeptune3D/display_firmware). I stopped working on this slightly because I lost interest, but also the TJC screens are terrible to work with, at least in English (There is no US or English version of the Software you **need** to edit the UI). I was able to make a proof of concept and even able to upload the new firmware through the existing UART connection, which was previously not possible. 

I have 100% learned from that, and I might go back to it one day, but I wanted to create this ideal display of mine with a great, beautiful animated UI that feels like you were actually supposed to use it. Looking at what I had on hand, I created Poseidon 1. A kinda in a way succesor to my previous project.

## Features

- Home screen
- Auto printer pairing
- Material 3 Expressive Design
- Flutter App
- On-device file printing
- On-device file deleting
- Off-the-shelf hardware
- Compact
- Live temperature
- Print File Stats
- Temperature Management (extruder & bed)
- move controls
- homing axis control
- Emergency Stop
- Automatic refreshing
- ergonomic 45-degree stand
- Automatic current print page
- cancel and pause/resume print
- fan speed
- Raspberry Pi OS
- Beautiful UI
- Moonraker integration
- Compatible with Klipper printers (built for Neptune 4 series)
- 3D printed case
- Step files
- HDMI & USB
- WiFi
- Bluetooth
- Pi Zero 2W
- Adjustable brightness
- cheap parts
- Works with OpenNept4une
- Auto Discovery
- And Much More

## Showcase

### Hardware:
#### Full - Build
![Build Image](https://github.com/Choccy-vr/Poseidon-1/blob/main/Media/Build.jpg)
#### Top - Build
![Build Top Image](https://github.com/Choccy-vr/Poseidon-1/blob/main/Media/Build-Top.jpg)
#### Side - Build
![Build Side Image](https://github.com/Choccy-vr/Poseidon-1/blob/main/Media/Build-Side.jpg)

### CAD:
#### Back CAD
![Back CAD Image](https://github.com/Choccy-vr/Poseidon-1/blob/main/Media/Back.png)
#### Bezel CAD
![Bezel CAD Image](https://github.com/Choccy-vr/Poseidon-1/blob/main/Media/Bezel.png)
#### Combined CAD
![CAD of Bezel and Back Image](https://github.com/Choccy-vr/Poseidon-1/blob/main/Media/CAD.png)

### Software:
#### Home Page
![Home Page](https://github.com/Choccy-vr/Poseidon-1/blob/main/Media/Home.png)
#### Files Page
![Files Page](https://github.com/Choccy-vr/Poseidon-1/blob/main/Media/Files.png)
#### Printing Page
![Printing Page](https://github.com/Choccy-vr/Poseidon-1/blob/main/Media/Printing.png)
#### Temperature Page
![Temp Page](https://github.com/Choccy-vr/Poseidon-1/blob/main/Media/Temp.png)
#### Move Page
![Move Page](https://github.com/Choccy-vr/Poseidon-1/blob/main/Media/Move.png)
#### Selection Page
![Selection Page](https://github.com/Choccy-vr/Poseidon-1/blob/main/Media/Selection.png)
#### Light Page
![Light Page](https://github.com/Choccy-vr/Poseidon-1/blob/main/Media/Light.png)
#### Macros Page
![Macros Page](https://github.com/Choccy-vr/Poseidon-1/blob/main/Media/Macros.png)

## Description

Poseidon 1 has two parts: hardware and software.

### Hardware:
Hardware consists of a 3.5 in display, which I had lying around. I would love it if I could have a bigger display. This small display is definitely too small and limits what I can do, but due to time constraints, I could not get it here in time. 

It also has a Raspberry Pi Zero 2W, a 1GHz quad-core super tiny SBC. Its performance is about equivalent to a Pi 3, which, paired with Flutter Pi, will be more than sufficient for my use case. It has a Mini HDMI port and two Micro USB ports, one for power and one for data. 

There is also another flaw with the hardware that, if given the choice of display, would not be an issue. The display I have is HDMI for video and USB for data and power. Which isn't bad, but when packed into a compact enclosure like this, it is not possible to route the cables in the enclosure, so they have to be externally routed. Which, if you think about it, is really an upside because you can use it as a tiny little touchscreen for your desk and connect it to your computer. Either way, if I had a choice, I would've picked DSI or similar

### Software:
The majority of this project is Software. 

There is an app that runs the UI and logic for Poseidon 1. This app is built with Flutter and Dart. While not the most efficient or good for low-end devices, the performance is still great with the Pi Zero 2W at pretty much a locked 60 fps. Flutter provides a means of super-easy, great-looking UI, and honestly, I have used it so much now that I have really grown on it. 

This sort of performance is possible with [flutter-pi](https://github.com/ardera/flutter-pi), which simplifies and optimizes running Flutter apps on Raspberry Pis. 

The app also uses Moonraker and Moonraker APIs to communicate with the printer. Moonraker is an industry standard in the world of Klipper 3d printers, so Moonraker is very robust and well-documented.

## Hardware Specifications
### Poseidon 1
- Compact 96mm x 36mm
- Waveshare 800x480 display
- Raspberry Pi Zero 2W
- 3D Printed Case
- HDMI & USB
### Display
- 3.5in
- 800x480
- HDMI
- IPS
- Adjustable Brightness
- 5-point capacitive touch
### Raspberry Pi
- Raspberry Pi Zero 2W
- 1 GHz 4 core 64bit procesador
- 512MB SDRAM
- 802.11 b/g/n wireless LAN
- Bluetooth 4.2, Bluetooth Low Energy (BLE)
- Mini HDMI port and micro USB On-The-Go (OTG) port
- Micro USB power
