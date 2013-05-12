# http://ftp.jaist.ac.jp/pub//sourceforge/t/ta/tass64/source/
asm=~/opt/c64/bin/64tass
asmopts=-m6502
src=game
experiment=raster-irq-test-1.asm

all:
	${asm} ${asmopts} -a -o ${src}.prg -l ${src}.labels -L ${src}.assembled.asm ${src}.asm

run: ${src}.prg
	x64 -autostartprgmode 1 -autostart-warp +truedrive +cart $<

experiment:
	${asm} ${experiment}.asm
	${asm} -l ${experiment}-disassembled.asm ${experiment}.asm

