set_property IOSTANDARD LVCMOS33 [get_ports clk]
set_property PACKAGE_PIN H4 [get_ports clk]


set_property IOSTANDARD TMDS_33 [get_ports {TMDSp[2]}]
set_property IOSTANDARD TMDS_33 [get_ports {TMDSp[1]}]
set_property IOSTANDARD TMDS_33 [get_ports {TMDSp[0]}]
set_property IOSTANDARD TMDS_33 [get_ports TMDSp_clock]
set_property IOSTANDARD TMDS_33 [get_ports {TMDSn[2]}]
set_property IOSTANDARD TMDS_33 [get_ports {TMDSn[1]}]
set_property IOSTANDARD TMDS_33 [get_ports {TMDSn[0]}]
set_property IOSTANDARD TMDS_33 [get_ports TMDSn_clock]

set_property PACKAGE_PIN L3 [get_ports TMDSp_clock]
set_property PACKAGE_PIN K3 [get_ports TMDSn_clock]
set_property PACKAGE_PIN B1 [get_ports {TMDSp[0]}]
set_property PACKAGE_PIN A1 [get_ports {TMDSn[0]}]
set_property PACKAGE_PIN E1 [get_ports {TMDSp[1]}]
set_property PACKAGE_PIN D1 [get_ports {TMDSn[1]}]
set_property PACKAGE_PIN G1 [get_ports {TMDSp[2]}]
set_property PACKAGE_PIN F1 [get_ports {TMDSn[2]}]

set_property IOSTANDARD LVCMOS33 [get_ports hdmi_red]
set_property IOSTANDARD LVCMOS33 [get_ports hdmi_grn]
set_property IOSTANDARD LVCMOS33 [get_ports hdmi_blu]
set_property IOSTANDARD LVCMOS33 [get_ports hdmi_int]
set_property IOSTANDARD LVCMOS33 [get_ports hdmi_vs]
set_property IOSTANDARD LVCMOS33 [get_ports hdmi_hs]
set_property IOSTANDARD LVCMOS33 [get_ports hdmi_clk]
set_property IOSTANDARD LVCMOS33 [get_ports hdmi_de]


set_property PACKAGE_PIN B20 [get_ports {hdmi_red}]
set_property PACKAGE_PIN E19 [get_ports {hdmi_grn}]
set_property PACKAGE_PIN D20 [get_ports {hdmi_blu}]
set_property PACKAGE_PIN C18 [get_ports {hdmi_int}]
set_property PACKAGE_PIN C22 [get_ports {hdmi_vs}]
set_property PACKAGE_PIN F18 [get_ports {hdmi_hs}]
set_property PACKAGE_PIN D17 [get_ports {hdmi_clk}]
set_property PACKAGE_PIN F19 [get_ports {hdmi_de}]



#create_clock -period 8.000 -name clk_in -waveform {0.000 4.000} [get_ports clk]
