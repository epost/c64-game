; in emacs, compile this file to a .PRG file using ~/opt/c64/bin/tmpx ${THISFILE}.asm
; in VICE, mount the .PRG File > Smart attach disk/tape
; do SYS 49152 (for start address * = $c000) 
		
		
* = $c000 

spr0_ptr = $07f8
spr0_x = $d000
spr0_y = $d001
spr0_col = $d027

spr1_ptr = $07f9
spr1_x = $d002
spr1_y = $d003
spr1_col = $d028
		

		jsr $e544				; clear screen
		lda #$00				; black bg and fg
		sta $d020
		sta $d021
		
		lda #13					; sprite 0 starts at 13 * 64 = 832 = $0340
		sta spr0_ptr

		ldx #$00	
fill_spr0
		lda spr0_data_2,x
		sta $0340,x
		inx
		cpx	#21*3
		bne fill_spr0

		
		lda #14					; sprite 0 starts at 14 * 64 = 896 
		sta spr1_ptr

		ldx #$00
fill_spr1	
		lda ship_data,x
		sta 14*64,x
		inx
		cpx	#21*3
		bne fill_spr1

		

		
								
		lda #$70 				;  set x and y for sprite 0
		sta spr0_x	
		sta spr0_y

		sta spr1_x 				;  set x and y for sprite 1
		lda #$80 				
		sta spr1_y

		lda #$05
		sta spr0_col			

		lda #$07
		sta spr1_col			
		
		lda #%00000011			; enable sprites 0 and 1
		sta $d015

		jsr init_screen_for_raster_int
loopje
		jmp loopje



int_handler		     			; we do our work here	

		inc spr0_x
		
int_handler_wrapup		
        asl $d019    			; ACK interrupt (to re-enable it)		
        pla
        tay
        pla
        tax
        pla
        rti			    	    ; return from interrupt


		
		;; 	--------------------------
        ;;  adapted from http://ocaoimh.ie/wp-content/uploads/2008/01/intro-to-programming-c64-demos.html#SECTION00086000000000000000
		;; --------------------------

init_screen_for_raster_int

        lda #$1b 				; clear hi bit of raster int scanline (lo is at $d012) and set text mode
        sta $d011   		 	
        ldx #$08				; single-colour
        stx $d016    			
        ldy #$14 				; screen at $0400, charset at $2000
        sty $d018    			
		
install_raster_int
        sei          			; turn off interrupts
        lda #$7f
        ldx #$01
        sta $dc0d  				; Turn off CIA 1 interrupts
        sta $dd0d    			; Turn off CIA 2 interrupts
        stx $d01a    			; Turn on raster interrupts

        lda #<int_handler	    ; set raster interrupt vector
        ldx #>int_handler	    
        sta $0314    			
        stx $0315
        ldy #$80     			; set scanline on which to trigger interrupt
        sty $d012

        lda $dc0d    ; ACK CIA 1 interrupts
        lda $dd0d    ; ACK CIA 2 interrupts
        asl $d019    ; ACK VIC interrupts
        cli

		rts


		
spr0_data_2
		.byte %00000000,%00000000,%00000000
		.byte %00000000,%11111111,%00000000
		.byte %00000011,%11111111,%11000000
		.byte %00000111,%10011001,%11100000
		.byte %00001111,%01100110,%11110000
		.byte %00001111,%01000010,%11110000
		.byte %00001111,%01000010,%11110000
		.byte %00001111,%10011001,%11110000
		.byte %00001111,%11111111,%11110000
		.byte %00001111,%01111110,%11110000
		.byte %00000111,%10000001,%11100000
		.byte %00000011,%11111111,%11000000
		.byte %00000000,%11111111,%00000000
		.byte %00000000,%00000000,%00000000
		.byte %00000000,%00000000,%00000000
		.byte %00000000,%00000000,%00000000
		.byte %00000000,%00000000,%00000000
		.byte %00000000,%00000000,%00000000
		.byte %00000000,%00000000,%00000000
		.byte %00000000,%00000000,%00000000
		.byte %00000000,%00000000,%00000000
		
ship_data
		.byte %00000000,%00000000,%00000000
		.byte %00000000,%00000000,%00000000
		.byte %00000000,%00000000,%00000000
		.byte %00000000,%00000000,%00000000
		.byte %00000000,%00000000,%00000000
		.byte %00000000,%00000000,%00000000
		.byte %00000000,%00000000,%00000000
		.byte %00000000,%00000000,%00000000
		.byte %00000000,%00000000,%00000000
		.byte %00000000,%00011000,%00000000
		.byte %00000000,%00011000,%00000000
		.byte %00000000,%00011000,%00000000
		.byte %00000000,%00011000,%00000000
		.byte %00000000,%00011000,%00000000
		.byte %00000000,%00111100,%00000000
		.byte %00000000,%01111110,%00000000
		.byte %00000000,%01100110,%00000000
		.byte %00010000,%11100111,%00001000
		.byte %00010000,%11100111,%00001000
		.byte %00010011,%11100111,%11001000
		.byte %00011111,%11111111,%11111000

spr0_data 
		.byte %00000000,%00000000,%00000000
		.byte %00000000,%11111111,%00000000
		.byte %00000011,%00000000,%11000000
		.byte %00000100,%01100110,%00100000
		.byte %00001000,%10011001,%00010000
		.byte %00001000,%10111101,%00010000
		.byte %00001000,%10111101,%00010000
		.byte %00001000,%01100110,%00010000
		.byte %00001000,%00000000,%00010000
		.byte %00001000,%10000001,%00010000
		.byte %00000100,%01111110,%00100000
		.byte %00000011,%00000000,%11000000
		.byte %00000000,%11111111,%00000000
		.byte %00000000,%00000000,%00000000
		.byte %00000000,%00000000,%00000000
		.byte %00000000,%00000000,%00000000
		.byte %00000000,%00000000,%00000000
		.byte %00000000,%00000000,%00000000
		.byte %00000000,%00000000,%00000000
		.byte %00000000,%00000000,%00000000
		.byte %00000000,%00000000,%00000000

		
