# The Graphics Gremlin - FPGA code

(Click here for the [main README](https://github.com/schlae/graphics-gremlin/blob/main/README.md))

The FPGA code is divided into two major sets of files, those for CGA graphics and those for MDA graphics. At some point I'll tidy up and make a nice organized directory tree, but for now they're all in the same place.

* mda\_top.v: The top level file instantiating the MDA graphics logic (Not used as no more RGBI port)
* mda70\_top.v: An alternative top level file for VGA compatible MDA graphics
* mda.v: Implements MDA ISA interface, IO registers and instantiates the CRTC, SRAM interface, sequencer, and pixel engine
* crtc6845.v: This is my mostly-accurate recreation of the old Motorola 6845 CRT controller chip. It generates all the sync timings as well as the character and row addresses. There are probably slight differences between it and the real thing.
* mda\_sequencer.v: Controls timing across the entire card, deciding when to fetch SRAM data, look up character bits from the character ROM, and allow ISA bus access to the SRAM
* mda\_vram.v: Implements the state machine to arbitrate ISA bus and pixel engine access to the video ram (external SRAM)
* mda\_pixel.v: This is the pixel engine. It takes data coming from the SRAM, looks up the pixels in the character ROM, and shifts the data out one pixel at a time. 
* mda\_attrib.v: The attribute generator applies video attributes to the raw pixel data, including brightness, underline, inverse video, blinking. It also applies the blinking cursor.
* mda\_vgaport.v: This module turns the digital MDA video signals into numbers to drive the resistor ladder DAC connected to the VGA port. If you (gasp) dislike amber monochrome monitors, then you can hack this code to make it green or white.
* mda\_hdmiport.v: This module turns the digital MDA video signals to drive the DVI transmitter. Will also adjust the colour based on switch selection.

CGA graphics logic is similar to MDA and shares the same crtc6845.v logic, but the cards are different enough that I couldn't share more.
* cga\_top.v: Instantiates top level CGA logic with 60 Hz refresh rate.
* cga70\_top.v: Instantiates top level CGA logic with 70Hz refresh rate if higher pixel clock is required. (Composite displays are unlikely to work in this mode)
* cga\_overscan_\_top.v: Instantiates top level CGA logic with 60Hz refresh rate and show overscan area. (Not all HDMI monitors can accept this)
* cga.v: Implements the ISA bus interface, CGA control registers, wait state generator, and most of the other CGA modules
* cga\_sequencer.v: Generates most of the timing signals used on the card, including memory fetches and pixel engine timing.
* cga\_vram.v: Implements a very basic address MUX for the SRAM interface. This actually causes too much CGA snow, and should be improved using the MDA VRAM interface as a model.
* cga\_pixel.v: The CGA pixel engine takes data from the SRAM, does a character lookup (text mode only), and shifts the data out 1 or 2 bits at a time, depending on the video mode.
* cga\_attrib.v: The attribute generator applies video attributes to the raw pixels data, including color, brightness, and blinking.
* cga\_composite.v: Contains the flip flops used to generate NTSC composite color as well as new sync pulses. The output is a 7-bit signal passed off to the green DAC channel for the RCA jack on the card.
* cga\_scandoubler.v: A very basic scan doubler to convert 15.7KHz CGA video to 31.4KHz VGA video. To save memory, this is done using 4-bit digital RGBI signals.
* cga\_vgaport.v: This module takes RGBI digital video from the scan doubler and turns it into numbers that drive the resistor ladder DAC connected to the VGA port. It produces CGA brown instead of dark yellow.
* cga\_hdmiport.v: This module takes RGBI digital video from the scan doubler to drive the DVI transmitter. Dark Yellow is still shown due to pin limitations.

Other miscellaneous files include:
* cga.hex and mda.hex: character ROM
* gremlin.pcf: The pin constraints file that determines what signals are tied to what pins on the FPGA
* isavideo\_t.v: A sloppy test bench that I used to validate and troubleshoot the rest of the logic.
* is61c5128\_t.v: A behavorial Verilog model of the SRAM chip.
* is61\_tester.v: A test bench I used to verify the SRAM chip behavioral model.

## Building

To build the project, you will need to install the tools from [Project IceStorm](http://www.clifford.at/icestorm/) (full instructions are available at that link). The Graphics Gremlin uses NextPNR, so make sure you install that.

Alternatively, you can install the [OSS Cad Suite](https://github.com/YosysHQ/oss-cad-suite-build) which is prebuilt and runs on a variety of platforms.

Once the tools are installed, just navigate to the Graphics Gremlin Verilog directory and run
```
mkdir build
make
```
If you have the FTDI programming cable hooked up to the card, you can also type `make prog`. As a convenience, `make reset` will not program the FPGA but will toggle its reset line which is useful if you change the red switch bank and don't want to cycle power on the host PC.

If the `make prog` command can't find the FTDI programming cable, make sure you have the udev rules set up.


