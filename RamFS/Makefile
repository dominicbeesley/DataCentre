VERSIONS=	100 101 102 103 104 200
TARGETS=	$(addprefix ramfs,$(VERSIONS))
SRC=		ramfs200.asm

all::	$(addsuffix .bin, $(TARGETS))

$(addsuffix .bin, $(TARGETS)): $(SRC)

ramfs%.bin: 
		beebasm -i $(SRC) -D VER=$* -d -v >ramfs$*.lst


clean::
	-rm $(addsuffix .bin, $(TARGETS))
	-rm $(addsuffix .lst, $(TARGETS))

install:: all
	cp ./*.bin ~/hostfs/roms65