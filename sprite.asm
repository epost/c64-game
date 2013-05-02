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
		
spr2_ptr = $07fa
spr2_x = $d004
spr2_y = $d005
spr2_col = $d029

spr_enable = $d015
		
spr_size_bytes = 3*21

joystick_1 = $dc01
joystick_2 = $dc00

;; static screen line the player is on
player_y_line = $a0


CHROUT  = $ffd2          ; CHROUT sends a character to the current output device
CR      = $0d            ; PETSCII code for Carriage Return



		
		
		
		lda #0					; black bg and fg
		sta $d020
		sta $d021
		jsr $e544				; clear screen

credits
        ldx #0           ; start with character 0
next
        lda message,x    ; read character X from message
        beq end_credits	 ; we're done when we read a zero byte
        jsr CHROUT       ; call CHROUT to output char to current output device (defaults to screen)
        inx              ; next character
        bne next         ; loop back while index is not zero (max string length 255 bytes)
end_credits

		
		lda #13					; sprite 0 starts at 13 * 64 = 832 = $0340
		sta spr0_ptr
		ldx #0
fill_spr0
		lda enemy_data,x
		sta 13*64,x
		inx
		cpx	#spr_size_bytes
		bne fill_spr0
		
		
		lda #14					; sprite 1 starts at address 14 * 64
		sta spr1_ptr
		ldx #0					; copy sprite 1 data
fill_spr1	
		lda ship_data,x
		sta 14*64,x
		inx
		cpx	#spr_size_bytes
		bne fill_spr1

		lda #9					; sprite 2 starts at address 15 * 64
		sta spr2_ptr
		ldx #0					; copy sprite 2 data
fill_spr2
		lda bullet_data,x
		sta 9*64,x
		inx
		cpx	#spr_size_bytes
		bne fill_spr2


		
		lda #$70 				;  set x and y for sprite 0
		sta spr0_x	
		sta spr0_y

		sta spr1_x 				;  set x and y for sprite 1
		lda #$a0 				
		sta spr1_y

		sta spr2_x 				;  set x and y for sprite 1
		sta spr2_y

		lda #magenta			; enemy
		sta spr0_col			

		lda #grey				; player
		sta spr1_col			

		lda #cyan				; bullets
		sta spr2_col			
		
		lda #%00000011			; enable sprites 0 and 1 (enemy, player)
		sta spr_enable

		jsr init_screen_for_raster_int
loopje
		jmp loopje


		;; --------------------------
        ;;  raster interrupt handler
		;; --------------------------

int_handler		     			; we do our work here	

		inc spr0_x
		inc spr0_x
		
		lda %00000100			; are there bullets onscreen?
		bit spr_enable			
		beq respawn_bullets_maybe
move_bullet
		dec spr2_y				; update bullet position
		bne skip_stop_bullets
stop_bullets
		lda #%11111011			; disable bullet sprite
		and spr_enable
		sta spr_enable
skip_stop_bullets
		
respawn_bullets_maybe		
		lda #16					; fire button pressed?
		bit joystick_1
		bne skip_respawn_bullets

		lda #$04
		sta $d021
		
		ldx spr1_x				; bullet x = player x
		ldy spr1_y				; bullet y = player y
		stx spr2_x
		sty spr2_y
		lda #%00000100			; enable bullet sprite
		ora spr_enable
		sta spr_enable

		lda #$00
		sta $d021

skip_respawn_bullets
		
		lda #8					; TODO should be #8 i think -- joystick right?
		bit joystick_1
		bne skip_move_player_right
		inc spr1_x
skip_move_player_right
		lda #4					; joystick left?
		bit joystick_1
		bne skip_move_player_left
		dec spr1_x
skip_move_player_left

		
int_handler_wrapup		
        asl $d019    			; ACK interrupt (to re-enable it)		
        pla
        tay
        pla
        tax
        pla
        rti			    	    ; return from interrupt


		
		;; --------------------------
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

message
        .null "(c) 2013 lemon / shinsetsu"
		
enemy_data
		.byte %00000000,%00000000,%00000000
		.byte %00000000,%11111111,%00000000
		.byte %00000011,%11111111,%11000000
		.byte %00000111,%10111101,%11100000
		.byte %00001111,%01000010,%11110000
		.byte %00001111,%01000010,%11110000
		.byte %00001111,%01000010,%11110000
		.byte %00001111,%10011001,%11110000
		.byte %00001111,%11111111,%11110000
		.byte %00001111,%10000001,%11110000
		.byte %00000111,%01111110,%11100000
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
		.byte %00000000,%00011000,%00000000
		.byte %00000000,%00011000,%00000000
		.byte %00000000,%00011000,%00000000
		.byte %00000000,%00011000,%00000000
		.byte %00000000,%00011000,%00000000
		.byte %00000000,%00011000,%00000000
		.byte %00000000,%00011000,%00000000
		.byte %00000000,%00111100,%00000000
		.byte %00000000,%00111100,%00000000
		.byte %00000000,%00111100,%00000000
		.byte %00000000,%01111110,%00000000
		.byte %00000000,%01111110,%00000000
		.byte %00010000,%11111111,%00001000
		.byte %00010000,%11100111,%00001000
		.byte %00010011,%11100111,%11001000
		.byte %00011111,%11100111,%11111000
		.byte %00011111,%11100111,%11111000
		.byte %00011111,%11111111,%11111000
		.byte %00010000,%00011000,%00001000

bullet_data
		.byte %00000000,%00000000,%00000000
		.byte %00000000,%00000000,%00000000
		.byte %00000000,%00000000,%00000000
		.byte %00000000,%00000000,%00000000
		.byte %00000000,%00000000,%00000000
		.byte %00000000,%00000000,%00000000
		.byte %00000000,%00000000,%00000000
		.byte %00000000,%00000000,%00000000
		.byte %00000000,%00000000,%00000000
		.byte %00000000,%00000000,%00000000
		.byte %00000000,%00000000,%00000000
		.byte %00000000,%00000000,%00000000
		.byte %00000000,%00000000,%00000000
		.byte %00000000,%00000000,%00000000
		.byte %00110000,%00000000,%00001100
		.byte %00110000,%00000000,%00001100
		.byte %00110000,%00000000,%00001100
		.byte %00110000,%00000000,%00001100
		.byte %00110000,%00000000,%00001100
		.byte %00000000,%00000000,%00000000
		.byte %00000000,%00000000,%00000000

		
black = 0
white = 1
red = 2
cyan = 3
magenta = 4
green = 5
blue = 6
yellow = 7 
orange = 8
brown = 9
pink = 10
dark = 11
grey = 12
light_green = 13
light_blue = 14
light_grey = 15
