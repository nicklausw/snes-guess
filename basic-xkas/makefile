CC = xkas
FIX = superfamicheck

TITLE = basic

EMU = D:\dev\emu\snes9x\snes9x.exe

MAIN = main.s

SFILES = $(wildcard *.s)
IFILES = $(wildcard *.i)

all: $(TITLE).sfc makefile
	$(EMU) $(TITLE).sfc

$(TITLE).sfc: $(SFILES) $(IFILES) makefile
	$(CC) -o $(TITLE).sfc $(MAIN)

$(SFILES):

$(IFILES):

clean:
	del $(TITLE).sfc
