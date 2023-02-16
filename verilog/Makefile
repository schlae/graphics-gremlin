# Graphics Gremlin
#
# Copyright (c) 2021 Eric Schlaepfer
# This work is licensed under the Creative Commons Attribution-ShareAlike 4.0
# International License. To view a copy of this license, visit
# http://creativecommons.org/licenses/by-sa/4.0/ or send a letter to Creative
# Commons, PO Box 1866, Mountain View, CA 94042, USA.
#

PROJ = isavideo
IMAGES = mda70_top mda_top cga_top sound_top
SOURCES = mda70_top.v mda_top.v mda.v crtc6845.v mda_vgaport.v mda_vram.v mda_attrib.v mda_sequencer.v mda_pixel.v cga_top.v cga.v cga_vgaport.v cga_sequencer.v cga_pixel.v cga_attrib.v cga_vram.v cga_composite.v cga_scandoubler.v sound_top.v sound.v saa1099.v ./jtopl/hdl/jtopl2.v ./jtopl/hdl/jtopl.v ./jtopl/hdl/jtopl_acc.v ./jtopl/hdl/jtopl_op.v ./jtopl/hdl/jtopl_eg.v ./jtopl/hdl/jtopl_pg.v ./jtopl/hdl/jtopl_lfo.v ./jtopl/hdl/jtopl_timers.v ./jtopl/hdl/jtopl_mmr.v ./jtopl/hdl/jtopl_reg.v ./jtopl/hdl/jtopl_div.v ./jtopl/hdl/jtopl_sh_rst.v ./jtopl/hdl/jtopl_pg_comb.v ./jtopl/hdl/jtopl_noise.v ./jtopl/hdl/jtopl_sh.v ./jtopl/hdl/jtopl_eg_comb.v ./jtopl/hdl/jtopl_eg_cnt.v ./jtopl/hdl/jtopl_exprom.v ./jtopl/hdl/jtopl_logsin.v ./jtopl/hdl/jtopl_single_acc.v ./jtopl/hdl/jtopl_eg_final.v ./jtopl/hdl/jtopl_eg_pure.v ./jtopl/hdl/jtopl_eg_step.v ./jtopl/hdl/jtopl_eg_ctrl.v ./jtopl/hdl/jtopl_pg_rhy.v ./jtopl/hdl/jtopl_pg_sum.v ./jtopl/hdl/jtopl_pg_inc.v ./jtopl/hdl/jtopl_pm.v ./jtopl/hdl/jtopl_reg_ch.v ./jtopl/hdl/jtopl_csr.v ./jtopl/hdl/jtopl_slot_cnt.v 
PIN_DEF =  gremlin.pcf
DEVICE = hx8k
ODIR = build
DEPS = $(addprefix $(ODIR)/,$(addsuffix .d,$(IMAGES)))

# Want to build report and main bin file
all: $(addprefix $(ODIR)/,$(addsuffix .rpt,$(IMAGES))) $(ODIR)/$(PROJ).binm

# removed %.v
$(ODIR)/%.json: $(SOURCES)
	yosys -p 'synth_ice40 -top $(basename $(notdir $@)) -json $@' $(SOURCES) -E $(basename $(notdir $@)).d
#	yosys -p 'synth_ice40 -top mda_top -json $@' $(SOURCES) -E $(DEPS)
#	@echo yosys -p 'synth_ice40 -top isavideo -json $@' $^ -E $(DEPS)
	echo $@

$(ODIR)/%.asc: $(ODIR)/%.json $(PIN_DEF)
# add -q to quiet lots of messages
	nextpnr-ice40 -q --$(DEVICE) --pcf $(PIN_DEF) --json $< --asc $@ --package tq144:4k
#	@echo nextpnr $< $@

$(ODIR)/%.bin: $(ODIR)/%.asc
	icepack $< $@
#	@echo icepack $< $@

# Combined multiboot image
$(ODIR)/%.binm: $(addprefix $(ODIR)/,$(addsuffix .bin, $(IMAGES)))
	icemulti -c -o $@ $^

$(ODIR)/%.rpt: $(ODIR)/%.asc
	icetime -d $(DEVICE) -mtr $@ $<
#	@echo icetime -d $(DEVICE) -mtr $@ $<

sim: $(ODIR)/$(PROJ)_t.vcd

$(ODIR)/$(PROJ)_t.vcd: $(PROJ)_t.v $(SOURCES) is61c5128_t.v

prog: $(ODIR)/$(PROJ).binm
#	iCEburn  -e -v -w  $<
	iceprog -p $<

sudo-prog: $(ODIR)/$(PROJ).bin
	@echo 'Executing prog as root!!!'
	iCEburn  -e -v -w  $<

clean:
	rm -f $(ODIR)/$(PROJ).blif $(ODIR)/$(PROJ).asc $(ODIR)/$(PROJ).bin $(ODIR)/$(PROJ).json $(ODIR)/$(PROJ).d $(ODIR)/*.bin $(ODIR)/*.binm $(ODIR)/*.rpt

reset:
	iceprog -t

%.vcd:
	iverilog $^ -o $(@:.vcd=.out)
	vvp $(@:.vcd=.out)

# Don't delete individual images
PRECIOUS: $(addsuffix .bin, $(addprefix $(ODIR)/,$(IMAGES)))

.PHONY: all prog clean reset

# Depsfile
-include $(DEPS)
