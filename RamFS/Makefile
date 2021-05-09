VERSIONS=	100 101 102 103 104 200
TARGETS=	$(addprefix RAMFS,$(VERSIONS))
SRC=		RAMFS200.asm

all::	$(addsuffix .bin, $(TARGETS))

$(addsuffix .bin, $(TARGETS)): $(SRC)

RAMFS%.bin:
		beebasm -i $(SRC) -D VER=$* -d -v >RAMFS$*.lst


clean::
	-rm $(addsuffix .bin, $(TARGETS))
	-rm $(addsuffix .lst, $(TARGETS))

install:: all
	cp ./*.bin ~/hostfs/roms65
