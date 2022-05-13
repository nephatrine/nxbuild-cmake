LIGHT_FORE=\#BE4D00
LIGHT_BACK=\#F5E1A4
DARK_FORE=\#E35205
DARK_BACK=\#03090F

all: nsis

clean:
	@rm -rf ../build-icons

nsis: nsis-header nsis-panel nsis-icon

nsis-header: ../tools/packaging/header-150x57.bmp

nsis-panel: ../tools/packaging/page-164x314.bmp

nsis-icon: ../tools/packaging/install.ico

../build-icons/logo-color.svg: logo-mono.svg
	@mkdir -p ../build-icons
	sed "s/#ffffff/$(LIGHT_FORE)/g" $< > $@

../build-icons/logo-simple.svg: logo-simple.svg
	@mkdir -p ../build-icons
	sed "s/#ffffff/$(LIGHT_FORE)/g" $< > $@

../build-icons/icon-16.png: ../build-icons/logo-simple.svg
	rsvg-convert -w 16 -h 16 -a -o $@ $<

../build-icons/icon-16-16.png: ../build-icons/icon-16.png
	convert $< -background transparent -gravity Center -extent "16x16" $@

../build-icons/icon-24.png: ../build-icons/logo-simple.svg
	rsvg-convert -w 24 -h 24 -a -o $@ $<

../build-icons/icon-24-24.png: ../build-icons/icon-24.png
	convert $< -background transparent -gravity Center -extent "24x24" $@

../build-icons/icon-32.png: ../build-icons/logo-color.svg
	rsvg-convert -w 32 -h 32 -a -o $@ $<

../build-icons/icon-32-32.png: ../build-icons/icon-32.png
	convert $< -background transparent -gravity Center -extent "32x32" $@

../build-icons/icon-48.png: ../build-icons/logo-color.svg
	rsvg-convert -w 48 -h 48 -a -o $@ $<

../build-icons/icon-48-48.png: ../build-icons/icon-48.png
	convert $< -background transparent -gravity Center -extent "48x48" $@

../build-icons/icon-55.png: ../build-icons/logo-color.svg
	rsvg-convert -w 55 -h 55 -a -o $@ $<

../build-icons/icon-55-57.png: ../build-icons/icon-55.png
	convert $< -background transparent -gravity Center -extent "57x57" $@

../build-icons/icon-82x160.png: ../build-icons/logo-color.svg
	rsvg-convert -w 82 -h 160 -a -o $@ $<

../build-icons/icon-82x160-164.png: ../build-icons/icon-82x160.png
	convert $< -background transparent -gravity Center -extent "164x164" $@

../build-icons/icon-256.png: ../build-icons/logo-color.svg
	rsvg-convert -w 256 -h 256 -a -o $@ $<

../build-icons/icon-256-256.png: ../build-icons/icon-256.png
	convert $< -background transparent -gravity Center -extent "256x256" $@

../tools/packaging/header-150x57.bmp: ../build-icons/icon-55-57.png
	convert -size "150x57" gradient:"#FFFFFF"-"$(LIGHT_BACK)" -distort SRT 135 $< -gravity Center -composite "BMP3:header.bmp"
	@mv header.bmp $@

../tools/packaging/page-164x314.bmp: ../build-icons/icon-82x160-164.png
	convert -size "164x314" gradient:"#FFFFFF"-"$(LIGHT_BACK)" -distort SRT 135 $< -gravity NorthEast -composite "BMP3:page.bmp"
	@mv page.bmp $@

../tools/packaging/install.ico: ../build-icons/icon-16-16.png ../build-icons/icon-24-24.png ../build-icons/icon-32-32.png ../build-icons/icon-48-48.png ../build-icons/icon-256-256.png
	convert -background transparent -gravity Center $< $@
