# --- Allegro Options ---
ALLEGRO_SOURCE = allegro5
ALLEGRO_BUILD = build
ALLEGRO_OPTS = \
	-DSHARED=off \
	-DWANT_DOCS=off \
	-DWANT_MEMFILE=off \
	-DWANT_PHYSFS=off \
	-DWANT_NATIVE_DIALOG=off \
	-DWANT_VIDEO=off \
	-DWANT_DEMO=off \
	-DWANT_EXAMPLES=off \
	-DWANT_TESTS=off

# --- Top-level Rules ---

all: debug

run: debug
	@dub run

debug: allegro
	@dub build --build=debug

release: allegro
	@dub build --build=release

clean:
	$(RM) -r $(ALLEGRO_BUILD)

# --- Allegro ---

allegro:
	@mkdir -p $(ALLEGRO_BUILD)
	@cd $(ALLEGRO_BUILD) && cmake ../$(ALLEGRO_SOURCE) $(ALLEGRO_OPTS) && $(MAKE)
