CC = ca65
LD = ld65
FIX = superfamicheck

TITLE = basic

EMU = higan

SFILES = $(wildcard *.s)
OFILES = $(subst .s,.o,$(SFILES))

all: $(TITLE).sfc
	$(EMU) $(TITLE).sfc

basic.sfc: $(OFILES)
	$(LD) $(OFILES) -o $(TITLE).sfc -C snes.cfg
	$(FIX) $(TITLE).sfc -S -f

%.o: %.s
	$(CC) $< -o $@

clean:
	rm -f $(OFILES) $(TITLE).sfc
