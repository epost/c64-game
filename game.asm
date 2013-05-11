;;; -----------------------------------------------------------------------------
;;; - Compile this file to a .PRG file using ~/opt/c64/bin/tmpx ${THISFILE}.asm
;;; - In VICE, mount the .PRG File > Smart attach disk/tape (Cmd-O)
;;;
;;; (c) 2013 Erik / SHINSETSU
;;; -----------------------------------------------------------------------------


USE_FFFE_NOT_0314 = 1			; undefine to use 0314 instead of fffe
SUPPRESS_COLOR_INIT = 1
		
zero_page_store			= $04
zero_page_temp_var		= zero_page_store

num_stars_front			= 14
star_positions_front	= zero_page_store +2
star_row_adrs_front_end	= star_positions_front + (num_stars_front*2) -2
star_cols_front 		= star_row_adrs_front_end + 2
star_kleurtjes_front	= star_cols_front + (num_stars_front*3)
star_kleurtjes_front_end= star_positions_front + (num_stars_front*5)-2

num_stars_back			= 14
star_positions_back		= zero_page_store + 2 + (num_stars_front*5)
star_kleurtjes_back_end	= star_positions_front + (num_stars_front*5) + (num_stars_back*5)-2

num_stars_mid 			= 14		
star_positions_mid		= zero_page_store + 2 + (num_stars_front*5) + (num_stars_back*5)

DUMMY_BYTE				= $00
		
;;; -----------------------------------------------------------------------------
;;; BASIC loader using SYS 2064
;;; -----------------------------------------------------------------------------

* = $0801

.byte $0c,$08,$d0,$07,$9e
.text " 2064"
.byte $00,$00,$00,$00

		
* = $0810 						; 2064 decimal

;;; -----------------------------------------------------------------------------
;;; initialize the screen
;;; -----------------------------------------------------------------------------

        lda #%00010000			; set text mode, 24 rows, no extended color mode
        sta $d011
        ldx #$08				; single colour
        stx $d016
        ldy #$18				; put screen ram at $0400, charset at $2000
        sty $d018

		lda #0					; set black bg and fg
		sta $d020
		sta $d021
		jsr $e544				; clear screen

		
		ldx #$ff
copy_char
		lda charset,x
		sta char_mem,x
		lda charset+$100,x
		sta char_mem+$100,x
		lda charset+$200,x
		sta char_mem+$200,x
		lda charset+$300,x
		sta char_mem+$300,x
		dex
		bne copy_char

		lda #white
		jsr fill_color_ram

		ldx #0
print		
		lda msg_signature,x
		beq print_done
		;; sta screen_ram+(11*40)+10,x
		sta screen_ram+(12*40)+10,x
		inx
		jmp print
print_done
		
;;; -----------------------------------------------------------------------------
;;; prepare our zero page data store including the starfield data
;;; -----------------------------------------------------------------------------
        
        ldx #(zero_page_data_src_end - zero_page_data_src)
fill_star_data
        lda zero_page_data_src,x
        sta zero_page_store,x
        dex
        bne fill_star_data

;;; -----------------------------------------------------------------------------
;;; initialize star field colours by screen row
;;; -----------------------------------------------------------------------------

first_color = white
second_color = grey
third_color = dark_grey
		
		lda #first_color		; this is the default star colour
		jsr fill_color_ram

		lda #second_color		; first pass through the loop
colorize_rows		
		ldx #num_stars_front-1
colorize_screen_row		
		ldy #40-1				; screen width in columns
colorize_char
color_ram_row_ptr_adr
		sta (star_kleurtjes_front_end),y
		dey
		bpl colorize_char
		dec color_ram_row_ptr_adr+1	; modify hardcoded screen ram ptr
		dec color_ram_row_ptr_adr+1	; modify hardcoded screen ram ptr
		dex
		bne colorize_screen_row

		
;; cmp #third_color		; repeat the code above for the next color?
;; ;; tax
;; ;; cpx #third_color		; repeat the code above for the next color?

;; 		beq done_coloring

;; 		lda #third_color
;; 		ldx #<star_kleurtjes_back_end
;; 		ldy #>star_kleurtjes_back_end
;; 		stx color_ram_row_ptr_adr+1
;; 		sty color_ram_row_ptr_adr+2
;; 		ldx #num_stars_back-1
;; loep jmp loep
;; 		jmp colorize_screen_row
;; done_coloring

.ifndef SUPPRESS_COLOR_INIT
		ldx #num_stars_back-1
		
		lda #third_color
colorize_screen_row2
		ldy #40							; screen width in columns
colorize_char2
color_ram_row_ptr_adr2
		sta (star_kleurtjes_back_end),y

		dey
		bpl colorize_char2
		dec color_ram_row_ptr_adr2+1	; modify hardcoded screen ram ptr
		dec color_ram_row_ptr_adr2+1	; modify hardcoded screen ram ptr
		dex
		bne colorize_screen_row2
.endif

;;; -----------------------------------------------------------------------------
;;; init sprites
;;; -----------------------------------------------------------------------------

        lda #13                 ; player sprite 0 starts at 13 * 64
        sta spr0_ptr
        lda #14					; bulletSCROLL_s
        sta spr1_ptr
        lda #15					; enemies are sprites 2 - 7
        sta spr2_ptr
        sta spr3_ptr
        sta spr4_ptr
        sta spr5_ptr
        sta spr6_ptr
        sta spr7_ptr
		
        ldx #spr_size_bytes		; TODO can't we let the assembler do this for us?
copy_sprites
        lda ship_data,x
        sta 13*64,x
        lda bullet_data,x
        sta 14*64,x
        lda enemy_data,x
        sta 15*64,x
        dex
        bne copy_sprites
        
        lda #30                 ; set x and y for sprite 0 (player)
        sta spr0_x              
        lda #$a0
        sta spr0_y
        lda #grey
        sta spr0_col            

        lda #light_green		; bullets (cyan, light_blue, light_green)
        sta spr1_col

		lda #40					; set x and y for sprites 2 - 7 (enemies)
		clc
		sta spr2_x	
		adc #20
		sta spr3_x
		adc #20
		sta spr4_x
		adc #20
		sta spr5_x
		adc #20
		sta spr6_x
		adc #20
		sta spr7_x

		lda #50
		sta spr2_y
		adc #20
		sta spr3_y
		adc #20
		sta spr4_y
		adc #20
		sta spr5_y
		adc #20
		sta spr6_y
		adc #20
		sta spr7_y

		lda #red
		sta spr2_col			
		lda #grey
		sta spr3_col


;;; -----------------------------------------------------------------------------
;;; start game
;;; -----------------------------------------------------------------------------

await_fire_btn
        lda #16                 ; fire button pressed?
        bit joystick_1
        bne await_fire_btn

		jsr $e544				; clear screen
        
        lda #%11111101          ; enable sprites 0 and 2 (player, enemy)
        sta spr_enable

		
		ldx #0
print_score
		lda msg_score,x
		beq print_score_done
		sta screen_ram + (23*40),x
		inx
		jmp print_score
print_score_done


;;; -----------------------------------------------------------------------------
;;; install raster interrupt handler
;;; -----------------------------------------------------------------------------
		
        sei                     ; turn off interrupts
        lda #$7f
        ldx #$01
        sta $dc0d               ; Turn off CIA 1 interrupts
        sta $dd0d               ; Turn off CIA 2 interrupts
        stx $d01a               ; Turn on raster interrupts
        lda $dc0d               ; ACK CIA 1 interrupts
        lda $dd0d               ; ACK CIA 2 interrupts

        lda #<int_handler       ; set raster interrupt vector
        ldx #>int_handler

.ifdef USE_FFFE_NOT_0314
        sta $fffe
        stx $ffff
.endif
.ifndef USE_FFFE_NOT_0314
        sta $0314               
        stx $0315
.endif
        ldy #$f0                ; set scanline on which to trigger interrupt
        sty $d012
		lda $d011				; scanline hi bit
		and #%01111111
		sta $d011

.ifdef USE_FFFE_NOT_0314
		lda #$35				; disable kernal and BASIC memory ($e000 - $ffff)
		sta $01
.endif

        asl $d019               ; ACK VIC interrupts
        cli

loop_pro_semper
		jmp loop_pro_semper

;;; -----------------------------------------------------------------------------
;;; main loop, implemented as a raster interrupt handler
;;; -----------------------------------------------------------------------------

int_handler

.ifdef USE_FFFE_NOT_0314
		pha						; needed if our raster int handler is set in fffe instead of 0314
		txa
		pha
		tya
		pha
.endif

        dec spr2_x				; update enemy positions
        dec spr2_x
        dec spr2_x

        dec spr3_x
        dec spr3_x
        dec spr3_x
        dec spr3_x
        dec spr3_x

        dec spr4_x
        dec spr4_x

        dec spr5_x
        dec spr5_x
        dec spr5_x

        dec spr6_x
        dec spr6_x
        dec spr6_x
        dec spr6_x
        dec spr6_x

        dec spr7_x
        dec spr7_x
        dec spr7_x
        dec spr7_x
        dec spr7_x

        lda #%00000010           ; update bullets - are there bullets onscreen?
        bit spr_enable          
        beq respawn_bullets_maybe
move_bullet
		lda spr1_x
		clc
		adc #12					; bullet speed
		sta spr1_x
        bcc skip_stop_bullets
stop_bullets
        lda #%11111101          ; disable bullet sprite
        and spr_enable
        sta spr_enable
skip_stop_bullets
        
respawn_bullets_maybe       
        lda #16                 ; fire button pressed?
        bit joystick_1
        bne skip_respawn_bullets

        ldx spr0_x              ; bullet x = player x
        ldy spr0_y              ; bullet y = player y
        stx spr1_x
        sty spr1_y
        lda #%00000010          ; enable bullet sprite
        ora spr_enable
        sta spr_enable

skip_respawn_bullets        
        
        lda #2                  ; read joystick and update player position
        bit joystick_1
        bne skip_move_player_down
		inc spr0_y
		inc spr0_y
skip_move_player_down
		lda #1
		bit joystick_1
		bne skip_move_player_up
		dec spr0_y
		dec spr0_y
skip_move_player_up

		lda spr_spr_collision	; any enemies being hit by bullets?
		ldx #$ff				; if so, reset to rightmost x-position
enemy_2_hit
		cmp #%00000110
		bne enemy_3_hit
		inc spr2_col
		stx spr2_x
		jmp disable_bullets

enemy_3_hit
		cmp #%00001010
		bne enemy_4_hit
		inc spr3_col
		stx spr3_x
		jmp disable_bullets

enemy_4_hit
		cmp #%00010010
		bne enemy_5_hit
		inc spr4_col
		stx spr4_x
		jmp disable_bullets

enemy_5_hit
		cmp #%00100010
		bne enemy_6_hit
		inc spr5_col
		stx spr5_x
		jmp disable_bullets

enemy_6_hit
		cmp #%01000010
		bne enemy_7_hit
		inc spr6_col
		stx spr6_x
		jmp disable_bullets

enemy_7_hit
		cmp #%10000010
		bne skip_enemy_hit
		inc spr7_col
		stx spr7_x
		jmp disable_bullets

disable_bullets
		lda #%11111101			; disable bullet sprite
		and spr_enable
		sta spr_enable

skip_enemy_hit

        
;;; -----------------------------------------------------------------------------
;;; update star field using smooth scrolling over 8 px, or by moving chars
;;; in screen ram if we've had all 8 px
;;; -----------------------------------------------------------------------------
		


		
;; smooth_scroll_using_scroll_reg
;;         lda scroll_x            ; do optional smooth scrolling
;;         and #%00000111
;;         tax
;;         dex
;;         bmi move_bg_chars		; reset scroll reg and move chars in screen ram
;;         lda scroll_x            ; smooth scroll 1 pixel to the left
;;         and #%11111000
;;         stx zero_page_temp_var
;;         ora zero_page_temp_var      
;;         sta scroll_x
;;         jmp skip_move_bg_chars
;; 
;; move_bg_chars
;; 
;;         lda #%00000111
;;         ora scroll_x        
;;         sta scroll_x
;;
;;         ;; ... do actual screen ram copying / moving here ...
;;
;; skip_move_bg_chars


		
;;; -----------------------------------------------------------------------------
;;; macro: scroll a single layer of the star field
;;; -----------------------------------------------------------------------------

SCROLL_STARS .macro

star_positions 	= \1
char_star 		= \2
num_rols		= \3
SUPPRESS_STA	= \4

num_stars				= 14
star_row_adrs_end		= star_positions + (num_stars*2) -2
star_cols 				= star_row_adrs_end +2
char_star_moving_row	= char_mem + (char_star*8) + 4
		
		
		lda char_star_moving_row; left-shift the row in the char tile containing the star
		clc

rol_i	.var num_rols			; rotate the star a given number of ROLs
do_rol	.lbl
		rol						; works if number of ROLs is even
rol_i	.var rol_i-1
		.ifne rol_i
		.goto do_rol
		.endif

		bcs move_chars
		sta char_star_moving_row
		jmp scroll_stars_done
		
move_chars
		rol						; rotate again to get carry into LSB
		sta char_star_moving_row		
        
        ldx #num_stars-1

        ldy #star_row_adrs_end	; self-modifying code: reset hardcoded pointers to end of table
        sty screen_ptr_adr_1+1           
        sty screen_ptr_adr_2+1           
        
next_star
		lda star_cols,x			; Y = star's screen column
        tay
        lda #char_empty			; clear star's old position with space char
.ifne SUPPRESS_STA
		sty zero_page_temp_var
		ldy #0
.endif
screen_ptr_adr_1
		sta (DUMMY_BYTE),y      ; hardcoded ptr into screen ram, will be modified
.ifne SUPPRESS_STA
		ldy zero_page_temp_var
.endif
        dey                     ; update star's screen column
        tya
        bne skip_respawn_star
respawn_star
        lda #38                 ; respawn star at the right of the screen
        ldy #38
skip_respawn_star       
        sta star_cols,x
        lda #char_star
.ifne SUPPRESS_STA
  sty zero_page_temp_var
  ldy #0
.endif
screen_ptr_adr_2
		sta (DUMMY_BYTE),y		; hardcoded ptr into screen ram, will be modified
.ifne SUPPRESS_STA
  ldy zero_page_temp_var
.endif		
        dec screen_ptr_adr_1+1	; self-modifying code: point DUMMY_BYTE 
        dec screen_ptr_adr_1+1	; to next star's data 
        dec screen_ptr_adr_2+1           
        dec screen_ptr_adr_2+1           
        
        dex
        bne next_star

scroll_stars_done

.endm

		#SCROLL_STARS star_positions_front, char_star_front, 1, 0
		;; #SCROLL_STARS star_positions_back, char_star_back, 2, 1
		#SCROLL_STARS star_positions_mid, char_star_mid, 2, 0
		
int_handler_wrapup      
        asl $d019               ; ACK interrupt (to re-enable it)       
        pla
        tay
        pla
        tax
        pla
        rti                     ; return from interrupt


;;; -----------------------------------------------------------------------------
;;; subroutine to set the screen color to the value of A
;;; -----------------------------------------------------------------------------

fill_color_ram
		ldx #0
		lda #green
fill_color_ram_next_pos
		sta color_ram,x
		sta color_ram+$100,x
        sta color_ram+$200,x
        sta color_ram+$300,x	; this goes beyond color ram, but hey...
        dex
        bne fill_color_ram_next_pos
		rts

		
sprite_data                
ship_data
        .byte %00000000,%00000000,%00000000
        .byte %00000000,%00000000,%00000000
        .byte %00000000,%00000000,%00000000
        .byte %00000000,%00000000,%00000000
        .byte %00000000,%00000000,%00000000
        .byte %00000000,%00000000,%00000000
        .byte %00000000,%00000000,%00000000
        .byte %00000000,%00000000,%00000000
        .byte %11100000,%00000000,%00000000
        .byte %11110000,%00000000,%00000000
        .byte %11111000,%00000000,%00000000
        .byte %01111111,%11111100,%00000000
        .byte %11111111,%10000011,%11111111
        .byte %01111010,%11111111,%11111111
        .byte %00110101,%11010101,%01111100
        .byte %00011111,%11111111,%11000000
        .byte %01111111,%00000000,%00000000
        .byte %11111111,%11111000,%00000000
        .byte %00000000,%00000000,%00000000
        .byte %00000000,%00000000,%00000000
        .byte %00000000,%00000000,%00000000

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
        .byte %00000110,%00000000,%00000000
        .byte %00000000,%00011100,%00000000
        .byte %00101100,%11111111,%00000000
        .byte %00000000,%00000100,%00000000
        .byte %00000000,%10000000,%00000000
        .byte %00000000,%00000011,%10000000
        .byte %10101100,%01111111,%11100000
        .byte %00000000,%00000000,%10000000
		.byte %00000011,%00000000,%00000000
		.byte %00000000,%00000000,%00000000

enemy_data
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
        .byte %00011100,%00111100,%00111000
        .byte %01100010,%11000111,%01000110
        .byte %01100001,%10011111,%10000100
        .byte %00000010,%01000111,%11000000
        .byte %11111111,%11111111,%11111111
        .byte %00110100,%11001100,%11011100
        .byte %00000111,%11111111,%11100000
        .byte %00000011,%11111111,%11000000
        .byte %00000000,%11111111,%00000000
        .byte %00000000,%00000000,%00000000

char_empty = " "
char_star_front	= 64 			; screen code
char_star_back = 65				; screen code
char_star_mid = 66				; screen code
		
charset	
		.include "font-8x8.lff.asm"		; the regular character font
		
		.byte %00000000 		; tile: a one-pixel star (char_star_front)
		.byte %00000000
		.byte %00000000
		.byte %00000000
		.byte %00000001			; <-- this row is shifted
		.byte %00000000
		.byte %00000000
		.byte %00000000

		.byte %00000000 		; tile: a one-pixel star (char_star_back)
		.byte %00000000
		.byte %00000000
		.byte %00000000
		.byte %00000001			; <-- this row is shifted
		.byte %00000000
		.byte %00000000
		.byte %00000000

		.byte %00000000 		; tile: a one-pixel row star (char_star_mid)
		.byte %00000000
		.byte %00000000
		.byte %00000000
		.byte %00000001			; <-- this row is shifted
		.byte %00000000
		.byte %00000000
		.byte %00000000

msg_signature		
.screen "(c) 2013 lemon/r&r"
.byte 0

msg_score
.screen "score 1979"
.byte 0

;;; -----------------------------------------------------------------------------
;;; data store to be copied to zero page -- TODO use '.offs' or something?
;;; -----------------------------------------------------------------------------
		
zero_page_data_src
		.byte $19, $79			; dummy, variable store
		
star_row_adrs_front_src
		
;;; starfield layer 0
		.word $5b8,	$608,	$4f0,	$658,	$4a0,	$478,	$658,	$680,	$608,	$608,	$658,	$4a0,	$478,	$5b8
		.byte 3,	27,	12,	31,	3,	23,	26,	4,	2,	15,	19,	6,	13,	24
		.word $d9b8,	$da08,	$d8f0,	$da58,	$d8a0,	$d878,	$da58,	$da80,	$da08,	$da08,	$da58,	$d8a0,	$d878,	$d9b8

;;; starfield layer 1
		.word $6a8,	$400,	$518,	$748,	$608,	$400,	$478,	$5b8,	$518,	$630,	$518,	$630,	$400,	$4f0
		.byte 36,	10,	0,	3,	35,	10,	17,	35,	37,	16,	19,	9,	5,	37
		.word $daa8,	$d800,	$d918,	$db48,	$da08,	$d800,	$d878,	$d9b8,	$d918,	$da30,	$d918,	$da30,	$db98,	$d8f0

;;; starfield layer 2
		.word $400,	$540,	$680,	$720,	$6a8,	$4a0,	$4f0,	$720,	$658,	$6d0,	$5e0,	$568,	$720,	$540
		.byte 16,	17,	14,	37,	38,	7,	38,	12,	6,	35,	31,	0,	5,	32
		.word $db98,	$d940,	$da80,	$db20,	$daa8,	$d8a0,	$d8f0,	$db20,	$da58,	$dad0,	$d9e0,	$d968,	$db20,	$d940

zero_page_data_src_end

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

spr3_ptr = $07fb
spr3_x = $d006
spr3_y = $d007
spr3_col = $d02a

spr4_ptr = $07fc
spr4_x = $d008
spr4_y = $d009
spr4_col = $d02b

spr5_ptr = $07fd
spr5_x = $d00a
spr5_y = $d00b
spr5_col = $d02c

spr6_ptr = $07fe
spr6_x = $d00c
spr6_y = $d00d
spr6_col = $d02d

spr7_ptr = $07ff
spr7_x = $d00e
spr7_y = $d00f
spr7_col = $d02e

spr_enable = $d015
spr_spr_collision = $d01e

spr_size_bytes = 3*21

screen_size_x_px = 320
screen_ram = $0400
screen_ram_size = 40*25
color_ram = $d800		
char_mem = $2000

scroll_x = $d016

joystick_1 = $dc01
joystick_2 = $dc00
		
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
dark_grey = 11
grey = 12
light_green = 13
light_blue = 14
light_grey = 15
