### Basic EEPROM storage test

Contains the string `EEPROM_V123` so that your emulator can detect EEPROM

Tests the basic flash operations and has a stresstest for EEPROM save storage.

Unfortunately, this can't be tested on hardware easily, it passes on my own emulator though, which I guess is worth something. 

To see what each test does, check the source.

#### Messages:

If you passed all tests: `Passed all tests`

If you failed a test: `Failed test XXXXXXXX`, where `XXXXXXXX` is the ID for the test you failed

If you get a black screen, it is likely that you do not return a 1 after writes have been completed. GBATek said the following:

> After the DMA, keep reading from the chip, by normal LDRH [DFFFF00h], until Bit 0 of the returned data becomes "1" (Ready). 

which is what I do to test that.
