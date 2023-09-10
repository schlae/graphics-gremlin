EESchema Schematic File Version 4
EELAYER 30 0
EELAYER END
$Descr A4 11693 8268
encoding utf-8
Sheet 4 6
Title "SRAM"
Date "2021-08-09"
Rev "2.1"
Comp ""
Comment1 ""
Comment2 ""
Comment3 ""
Comment4 ""
$EndDescr
$Comp
L Memory_RAM:IS61C5128AL-10KLI U?
U 1 1 603A5B22
P 5700 3700
AR Path="/603A5B22" Ref="U?"  Part="1" 
AR Path="/603A03FF/603A5B22" Ref="U7"  Part="1" 
F 0 "U7" H 5800 5100 50  0000 C CNN
F 1 "IS61WV5128BLL-10KLI" H 6150 5000 50  0000 C CNN
F 2 "Active:SOJ127P1118X376-36" H 5200 4850 50  0001 C CNN
F 3 "https://www.mouser.com/datasheet/2/198/61-64WV5128Axx-Bxx-258353.pdf" H 5700 3700 50  0001 C CNN
F 4 "870-61WV5128B10KLI" H 0   0   50  0001 C CNN "Mouser"
	1    5700 3700
	1    0    0    -1  
$EndComp
Wire Wire Line
	4850 2600 5100 2600
Text Label 4850 2600 0    50   ~ 0
RA0
Entry Wire Line
	4750 2500 4850 2600
Wire Wire Line
	4850 2700 5100 2700
Text Label 4850 2700 0    50   ~ 0
RA1
Entry Wire Line
	4750 2600 4850 2700
Wire Wire Line
	4850 2800 5100 2800
Text Label 4850 2800 0    50   ~ 0
RA2
Entry Wire Line
	4750 2700 4850 2800
Wire Wire Line
	4850 2900 5100 2900
Text Label 4850 2900 0    50   ~ 0
RA3
Entry Wire Line
	4750 2800 4850 2900
Wire Wire Line
	4850 3000 5100 3000
Text Label 4850 3000 0    50   ~ 0
RA4
Entry Wire Line
	4750 2900 4850 3000
Wire Wire Line
	4850 3100 5100 3100
Text Label 4850 3100 0    50   ~ 0
RA5
Entry Wire Line
	4750 3000 4850 3100
Wire Wire Line
	4850 3200 5100 3200
Text Label 4850 3200 0    50   ~ 0
RA6
Entry Wire Line
	4750 3100 4850 3200
Wire Wire Line
	4850 3300 5100 3300
Text Label 4850 3300 0    50   ~ 0
RA7
Entry Wire Line
	4750 3200 4850 3300
Wire Wire Line
	4850 3400 5100 3400
Text Label 4850 3400 0    50   ~ 0
RA8
Entry Wire Line
	4750 3300 4850 3400
Wire Wire Line
	4850 3500 5100 3500
Text Label 4850 3500 0    50   ~ 0
RA9
Entry Wire Line
	4750 3400 4850 3500
Wire Wire Line
	4850 3600 5100 3600
Text Label 4850 3600 0    50   ~ 0
RA10
Entry Wire Line
	4750 3500 4850 3600
Wire Wire Line
	4850 3700 5100 3700
Text Label 4850 3700 0    50   ~ 0
RA11
Entry Wire Line
	4750 3600 4850 3700
Wire Wire Line
	4850 3800 5100 3800
Text Label 4850 3800 0    50   ~ 0
RA12
Entry Wire Line
	4750 3700 4850 3800
Wire Wire Line
	4850 3900 5100 3900
Text Label 4850 3900 0    50   ~ 0
RA13
Entry Wire Line
	4750 3800 4850 3900
Wire Wire Line
	4850 4000 5100 4000
Text Label 4850 4000 0    50   ~ 0
RA14
Entry Wire Line
	4750 3900 4850 4000
Wire Wire Line
	4850 4100 5100 4100
Text Label 4850 4100 0    50   ~ 0
RA15
Entry Wire Line
	4750 4000 4850 4100
Wire Wire Line
	4850 4200 5100 4200
Text Label 4850 4200 0    50   ~ 0
RA16
Entry Wire Line
	4750 4100 4850 4200
Wire Wire Line
	4850 4300 5100 4300
Text Label 4850 4300 0    50   ~ 0
RA17
Entry Wire Line
	4750 4200 4850 4300
Wire Wire Line
	4850 4400 5100 4400
Text Label 4850 4400 0    50   ~ 0
RA18
Entry Wire Line
	4750 4300 4850 4400
Wire Wire Line
	6300 2600 6600 2600
Text Label 6600 2600 2    50   ~ 0
RD0
Entry Wire Line
	6600 2600 6700 2500
Wire Wire Line
	6300 2700 6600 2700
Text Label 6600 2700 2    50   ~ 0
RD1
Entry Wire Line
	6600 2700 6700 2600
Wire Wire Line
	6300 2800 6600 2800
Text Label 6600 2800 2    50   ~ 0
RD2
Entry Wire Line
	6600 2800 6700 2700
Wire Wire Line
	6300 2900 6600 2900
Text Label 6600 2900 2    50   ~ 0
RD3
Entry Wire Line
	6600 2900 6700 2800
Wire Wire Line
	6300 3000 6600 3000
Text Label 6600 3000 2    50   ~ 0
RD4
Entry Wire Line
	6600 3000 6700 2900
Wire Wire Line
	6300 3100 6600 3100
Text Label 6600 3100 2    50   ~ 0
RD5
Entry Wire Line
	6600 3100 6700 3000
Wire Wire Line
	6300 3200 6600 3200
Text Label 6600 3200 2    50   ~ 0
RD6
Entry Wire Line
	6600 3200 6700 3100
Wire Wire Line
	6300 3300 6600 3300
Text Label 6600 3300 2    50   ~ 0
RD7
Entry Wire Line
	6600 3300 6700 3200
Wire Wire Line
	5100 4600 5000 4600
Wire Wire Line
	5000 4700 5100 4700
Wire Wire Line
	5100 4800 4000 4800
$Comp
L power:+3V3 #PWR?
U 1 1 603A5B7F
P 5700 2250
AR Path="/603A5B7F" Ref="#PWR?"  Part="1" 
AR Path="/603A03FF/603A5B7F" Ref="#PWR042"  Part="1" 
F 0 "#PWR042" H 5700 2100 50  0001 C CNN
F 1 "+3V3" H 5715 2423 50  0000 C CNN
F 2 "" H 5700 2250 50  0001 C CNN
F 3 "" H 5700 2250 50  0001 C CNN
	1    5700 2250
	1    0    0    -1  
$EndComp
Wire Wire Line
	5700 2250 5700 2400
Wire Wire Line
	5700 5000 5700 5100
$Comp
L power:GND #PWR?
U 1 1 603A5B87
P 5700 5100
AR Path="/603A5B87" Ref="#PWR?"  Part="1" 
AR Path="/603A03FF/603A5B87" Ref="#PWR043"  Part="1" 
F 0 "#PWR043" H 5700 4850 50  0001 C CNN
F 1 "GND" H 5705 4927 50  0000 C CNN
F 2 "" H 5700 5100 50  0001 C CNN
F 3 "" H 5700 5100 50  0001 C CNN
	1    5700 5100
	1    0    0    -1  
$EndComp
Wire Bus Line
	6700 2300 7400 2300
Wire Bus Line
	4750 2300 4150 2300
Text HLabel 7400 2300 2    50   BiDi ~ 0
RD[0..7]
Text HLabel 4150 2300 0    50   Input ~ 0
RA[0..18]
Text HLabel 4000 4800 0    50   Input ~ 0
~RAM_WE
$Comp
L Device:C_Small C?
U 1 1 614E7978
P 7200 3900
AR Path="/614E7978" Ref="C?"  Part="1" 
AR Path="/6043556F/614E7978" Ref="C?"  Part="1" 
AR Path="/603A03FF/614E7978" Ref="C28"  Part="1" 
F 0 "C28" H 7292 3946 50  0000 L CNN
F 1 "1u" H 7292 3855 50  0000 L CNN
F 2 "Capacitor_SMD:C_0603_1608Metric" H 7200 3900 50  0001 C CNN
F 3 "~" H 7200 3900 50  0001 C CNN
F 4 "810-CGA3E1X7R1C105AC" H 0   0   50  0001 C CNN "Mouser"
	1    7200 3900
	1    0    0    -1  
$EndComp
$Comp
L Device:C_Small C?
U 1 1 614E797E
P 7450 3900
AR Path="/614E797E" Ref="C?"  Part="1" 
AR Path="/6043556F/614E797E" Ref="C?"  Part="1" 
AR Path="/603A03FF/614E797E" Ref="C29"  Part="1" 
F 0 "C29" H 7542 3946 50  0000 L CNN
F 1 "1u" H 7542 3855 50  0000 L CNN
F 2 "Capacitor_SMD:C_0603_1608Metric" H 7450 3900 50  0001 C CNN
F 3 "~" H 7450 3900 50  0001 C CNN
F 4 "810-CGA3E1X7R1C105AC" H 0   0   50  0001 C CNN "Mouser"
	1    7450 3900
	1    0    0    -1  
$EndComp
Wire Wire Line
	7200 4000 7200 4050
Wire Wire Line
	7450 4000 7450 4050
Wire Wire Line
	7200 3800 7200 3750
Wire Wire Line
	7200 3750 7450 3750
Wire Wire Line
	7450 3750 7450 3800
Wire Wire Line
	7450 3750 7450 3650
Connection ~ 7450 3750
Wire Wire Line
	7200 4050 7450 4050
Wire Wire Line
	7450 4050 7450 4150
Connection ~ 7450 4050
$Comp
L power:+3V3 #PWR?
U 1 1 614EBB64
P 7450 3650
AR Path="/614EBB64" Ref="#PWR?"  Part="1" 
AR Path="/603A03FF/614EBB64" Ref="#PWR074"  Part="1" 
F 0 "#PWR074" H 7450 3500 50  0001 C CNN
F 1 "+3V3" H 7465 3823 50  0000 C CNN
F 2 "" H 7450 3650 50  0001 C CNN
F 3 "" H 7450 3650 50  0001 C CNN
	1    7450 3650
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR?
U 1 1 614EC04E
P 7450 4150
AR Path="/614EC04E" Ref="#PWR?"  Part="1" 
AR Path="/603A03FF/614EC04E" Ref="#PWR075"  Part="1" 
F 0 "#PWR075" H 7450 3900 50  0001 C CNN
F 1 "GND" H 7455 3977 50  0000 C CNN
F 2 "" H 7450 4150 50  0001 C CNN
F 3 "" H 7450 4150 50  0001 C CNN
	1    7450 4150
	1    0    0    -1  
$EndComp
Wire Wire Line
	5000 4600 5000 4700
Connection ~ 5000 4700
Wire Wire Line
	5000 4700 5000 5100
$Comp
L power:GND #PWR?
U 1 1 612B8100
P 5000 5100
AR Path="/612B8100" Ref="#PWR?"  Part="1" 
AR Path="/603A03FF/612B8100" Ref="#PWR083"  Part="1" 
F 0 "#PWR083" H 5000 4850 50  0001 C CNN
F 1 "GND" H 5005 4927 50  0000 C CNN
F 2 "" H 5000 5100 50  0001 C CNN
F 3 "" H 5000 5100 50  0001 C CNN
	1    5000 5100
	1    0    0    -1  
$EndComp
Text Notes 7100 6800 0    100  ~ 0
GRAPHICS GREMLIN (with HDMI)
Text Notes 7100 6950 0    50   ~ 0
DESIGN BY @TubeTimeUS\nModified by @yeokm1
Text Notes 550  7700 0    50   ~ 0
This work is licensed under the Creative Commons Attribution-ShareAlike 4.0 International License. \nTo view a copy of this license, visit http://creativecommons.org/licenses/by-sa/4.0/ or send\na letter to Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
Wire Bus Line
	6700 2300 6700 3200
Wire Bus Line
	4750 2300 4750 4300
$EndSCHEMATC
