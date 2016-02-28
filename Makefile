# resources contains version-controlled files that are build into content
CONTENT_SOURCE = resources
CONTENT_DEST = content

COPY_FILES := \
	$(wildcard $(CONTENT_SOURCE)/*.json) \
	$(wildcard $(CONTENT_SOURCE)/*.ttf) \
	$(wildcard $(CONTENT_SOURCE)/*.wav)

IMAGE_FILES := $(wildcard $(CONTENT_SOURCE)/*.ase)
MUSIC_FILES := $(wildcard $(CONTENT_SOURCE)/*.mmpz)

# cmake options for building allegro statically and leaving out unneeded bits
ALLEGRO_BUILD = build
ALLEGRO_SOURCE = allegro5
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

debug: allegro content
	@dub build --build=debug --config=client
	@dub build --build=debug --config=server

release: allegro content
	@dub build --build=release --config=client
	@dub build --build=release --config=server

run: debug
	@dub run

clean:
	$(RM) -r $(ALLEGRO_BUILD)
	$(RM) -r $(CONTENT_DEST)

# --- Allegro ---

allegro:
	@mkdir -p $(ALLEGRO_BUILD)
	@cd $(ALLEGRO_BUILD) && cmake ../$(ALLEGRO_SOURCE) $(ALLEGRO_OPTS) && $(MAKE)

# --- Content Pipeline ---

content: content_dir images music copy_files

content_dir:
	@mkdir -p $(CONTENT_DEST)

# Copy files from resource to content
copy_files: $(COPY_FILES:$(CONTENT_SOURCE)/%=$(CONTENT_DEST)/%)

$(CONTENT_DEST)/% : $(CONTENT_SOURCE)/%
	cp $(CONTENT_SOURCE)/$* $(CONTENT_DEST)/$*

# Use aseprite to convert .ase to .png
images: $(IMAGE_FILES:$(CONTENT_SOURCE)/%.ase=$(CONTENT_DEST)/%.png)

$(CONTENT_DEST)/%.png : $(CONTENT_SOURCE)/%.ase
	@echo building image $*
	@aseprite --batch --sheet $(CONTENT_DEST)/$*.png $(CONTENT_SOURCE)/$*.ase --data /dev/null

# Use mmpz to render .mmpz files into .ogg files
music: $(MUSIC_FILES:$(CONTENT_SOURCE)/%.mmpz=$(CONTENT_DEST)/%.ogg)

# lmms sometimes crashes after completely rendering the file
# this silently assumes success even if lmms 'fails'
$(CONTENT_DEST)/%.ogg : $(CONTENT_SOURCE)/%.mmpz
	@echo building song $*
	@-! { lmms -r $(CONTENT_SOURCE)/$*.mmpz -f ogg -b 64 -o $(CONTENT_DEST)/$*.ogg --loop ; } >/dev/null 2>&1
