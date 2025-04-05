## This folder contains the full - compiled stm32 projects for the microcontroller


With the **e5_test** project it will only sample the filter output as labled by the input headers on the PCB

with the **e5_double_sample** project, it will sample the filter output, as well as the sync pulse output from the waveform generator through PB3 on the PCB



**PLEASE NOTE:** this board cannot be flashed via the USB-C port, it only provides p
ower and a UART link over USB. To flash the board you need a ST-Link device. I w
ould recomend: [ST-LinkV3Minie](https://www.digikey.ca/en/products/detail/stmicroelectronics/STLINK-V3MINIE/16284301)

This can be connected to the ARM SWD header on the PCB, and the MCU can be flash
ed via the STM32 programmer tool or the CLI programmer tool.

**Using the stm32_programmer_cli tool please use the following commands:**

**Erase board flash:**
```
stm32_programmer_cli -c port=SWD -e all
```

**Program board:**
```
stm32_programmer_cli -c port=SWD -w <PATH to .hex file> 0x08000000
```
