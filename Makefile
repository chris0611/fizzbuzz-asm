AS = yasm
LD = mold
ASFLAGS = -f elf64

.PHONY: all clean

fizzbuzz: fizzbuzz.o
	$(LD) -o $@ $^

%.o: %.asm
	$(AS) $(ASFLAGS) -o $@ $^

clean:
	rm -f *.o fizzbuzz
