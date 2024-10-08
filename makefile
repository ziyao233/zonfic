MERGE		?= lmerge
LUA		?= lua5.4

SOURCES		:= zonfic.lua configfile.lua expression.lua util.lua
OUTPUT		:= zonfic

.PHONY: default clean

default: $(OUTPUT)

$(OUTPUT): $(SOURCES)
	$(MERGE) -ishb $(SOURCES) -o $(OUTPUT) -m zonfic.lua -i $(LUA)

clean:
	-rm -rf $(OUTPUT)
