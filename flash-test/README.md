### Basic flash storage test

Contains the string `FLASH_V123` so that your emulator can detect flash

Tests the basic flash operations and has a stresstest for Flash save storage.

Unfortunately, this can't be tested on hardware easily, it passes on my own emulator though, which I guess is worth something. 

To see what each test does, check the source.

#### Messages:

If you passed all tests: `Passed all tests`

If you failed a test: `Failed test XXXXXXXX`, where `XXXXXXXX` is the ID for the test you failed

If you failed a test, a value in the top left might appear. This is the address offset from `0E000000` where your output differed from the expected output.
