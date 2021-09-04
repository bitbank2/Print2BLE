Print2BLE
---------
Copyright (c) 2021 BitBank Software, Inc.<br>
Written by Larry Bank<br>
larry@bitbanksoftware.com<br>
<br>
![Print2BLE](/ble_printers.jpg?raw=true "Supported Printers")
<br>
What is it?<br>
-----------

This project is a MacOS GUI application to print image files on inexpensive Bluetooth Low Energy thermal printers. It allows you to drag supported image files (e.g. JPEG, PNG, BMP, TIFF, GIF) onto a window, convert them to 1-bpp dithered and then send them to the printer.<br>

Why did you write it?
--------------------
I've been experimenting with BLE thermal printers on microcontrollers and wanted to explore BLE client (central) programming on MacOS to talk to these same devices. This then morphed into the idea of making a simple drag+drop app to allow printing of images. By sharing this code, hopefully other people will find it a useful resource for info about BLE programming, manipulating images, and communicating with 'unsupported/undocumented' thermal printers.<br>

How to use it?
--------------
Upon running the app, you will be presented with a window containing 2 push buttons. The <b>connect</b> button will scan for supported printers and connect to the first one it finds. The status text will update to show that it connected to the named device. Next, drag an image onto the window from the Finder. A preview will display how it will look on paper. If you're satisfied with the results, press the <b>print</b> button.<br>

If you find this code useful, please consider becoming a sponsor or sending a donation.

[![paypal](https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=SR4F44J2UR8S4)

