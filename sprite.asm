;;; -----------------------------------------------------------------------------
;;; - Compile this file to a .PRG file using ~/opt/c64/bin/tmpx ${THISFILE}.asm
;;; - In VICE, mount the .PRG File > Smart attach disk/tape (Cmd-O)
;;;
;;; (c) 2013 Erik / SHINSETSU
;;; -----------------------------------------------------------------------------
		
zero_page_store = $04
zero_page_temp_var	= zero_page_store
star_positions_white = zero_page_store +2
num_stars_white = 13
star_row_adrs_white_end = (star_positions_white + (num_stars_white*2)) -2
star_cols_white = star_positions_white + (num_stars_white*2)
		
DUMMY_BYTE = $00
		
;;; -----------------------------------------------------------------------------
;;; BASIC loader using SYS 2064
;;; -----------------------------------------------------------------------------

* = $0801

.byte $0c,$08,$d0,$07,$9e
.text " 2064"
.byte $00,$00,$00,$00

		
* = $0810

;;; -----------------------------------------------------------------------------
;;; initialize the screen
;;; -----------------------------------------------------------------------------
		
		lda #0					; set black bg and fg
		sta $d020
		sta $d021
		jsr $e544				; clear screen

		ldx #$ff
		lda #blue
init_color_ram
		sta color_ram,x
		sta color_ram+$100,x
        sta color_ram+$200,x
        dex
        bne init_color_ram
        
        ldx #$e8                ; clear last bit of screen from $300 to $3e8
init_color_ram_last_chunk
        sta color_ram+$300,x
        dex
        bne init_color_ram_last_chunk

        
;;; -----------------------------------------------------------------------------
;;; draw a simple static star field
;;; -----------------------------------------------------------------------------
        
        ldx #(zero_page_data_src_end - zero_page_data_src)
fill_star_data
        lda zero_page_data_src,x
        sta zero_page_store,x
        dex
        bne fill_star_data

;;; -----------------------------------------------------------------------------
;;; init sprites
;;; -----------------------------------------------------------------------------

        lda #13                 ; sprite 0 starts at 13 * 64 = 832 = $0340
        sta spr0_ptr
        ldx #0
fill_spr0
        lda enemy_data,x
        sta 13*64,x
        inx
        cpx #spr_size_bytes
        bne fill_spr0
        

        lda #14                 ; sprite 1 starts at address 14 * 64
        sta spr1_ptr
        ldx #0                  ; copy sprite 1 data
fill_spr1   
        lda ship_data,x
        sta 14*64,x
        inx
        cpx #spr_size_bytes
        bne fill_spr1

        lda #9                  ; sprite 2 starts at address 15 * 64
        sta spr2_ptr
        ldx #0                  ; copy sprite 2 data
fill_spr2
        lda bullet_data,x
        sta 9*64,x
        inx
        cpx #spr_size_bytes
        bne fill_spr2       
        
        lda #$70                ;  set x and y for sprite 0 (enemy)
        sta spr0_x  
        lda #100            
        sta spr0_y
        lda #magenta
        sta spr0_col            

        lda #30                 ;  set x and y for sprite 1 (player)
        sta spr1_x              
        lda #$e0                
        sta spr1_y
        lda #grey
        sta spr1_col            

        lda #cyan               ; bullets
        sta spr2_col            
        
        lda #%00000011          ; enable sprites 0 and 1 (enemy, player)
        sta spr_enable

        jsr init_screen_for_raster_int
loopje
        jmp loopje


;;; -----------------------------------------------------------------------------
;;; main loop, implemented as a raster interrupt handler
;;; -----------------------------------------------------------------------------

int_handler                     ; we do our work here   

        dec spr0_x
        dec spr0_x
        
        lda %00000100           ; are there bullets onscreen?
        bit spr_enable          
        beq respawn_bullets_maybe
move_bullet
        inc spr2_x              ; update bullet position
        beq stop_bullets
        inc spr2_x              ; update bullet position
        beq stop_bullets
        inc spr2_x              ; update bullet position
        beq stop_bullets
        inc spr2_x              ; update bullet position
        beq stop_bullets
        inc spr2_x              ; update bullet position
        beq stop_bullets
        jmp skip_stop_bullets
stop_bullets
        lda #%11111011          ; disable bullet sprite
        and spr_enable
        sta spr_enable
skip_stop_bullets
        
respawn_bullets_maybe       
        lda #16                 ; fire button pressed?
        bit joystick_1
        bne skip_respawn_bullets

        lda #$04
        sta $d021
        
        ldx spr1_x              ; bullet x = player x
        ldy spr1_y              ; bullet y = player y
        stx spr2_x
        sty spr2_y
        lda #%00000100          ; enable bullet sprite
        ora spr_enable
        sta spr_enable

        lda #$00
        sta $d021

skip_respawn_bullets        
        
        lda #2                  ; read joystick and update player position
        bit joystick_1
        bne skip_move_player_down
        inc spr1_y
skip_move_player_down
        lda #1
        bit joystick_1
        bne skip_move_player_up
        dec spr1_y
skip_move_player_up

        lda #%00000101
        cmp spr_spr_collision
        bne skip_enemy_hit
        inc spr0_col
        lda #%11111011          ; disable bullet sprite
        and spr_enable
        sta spr_enable

skip_enemy_hit

        
;;; -----------------------------------------------------------------------------
;;; update star field
;;; -----------------------------------------------------------------------------

        lda scroll_x            ; do optional smooth scrolling
        and #%00000111
        tax
        dex
        bmi shift_bg_chars
        lda scroll_x            ; smooth scroll 1 pixel to the left
        and #%11111000
        stx zero_page_temp_var
        ora zero_page_temp_var      
        sta scroll_x
        jmp skip_shift_bg_chars

shift_bg_chars

        lda #%00000111
        ora scroll_x        
        sta scroll_x
        
        ldx #(num_stars_white)-1

        ldy #star_row_adrs_white_end    ; self-modifying code: reset hardcoded pointers to end of table
        sty modme2a+1           
        sty modme2b+1           
        
next_star
modme1  lda star_cols_white,x   ; Y = star's screen column
        tay

        lda #$20                ; clear star's old position with space char
modme2a sta (DUMMY_BYTE),y      ; this hardcoded reference will be modified

        dey                     ; update star's screen column
        tya
        bne skip_respawn_star
respawn_star
        lda #38                 ; respawn star at the right of the screen
        ldy #38
skip_respawn_star       
        sta star_cols_white,x
        
        lda star_char_1
modme2b sta (DUMMY_BYTE),y      ; this hardcoded reference will be modified
        dec modme2a+1           ; self-modifying code: point to next star's data 
        dec modme2a+1           ; self-modifying code: point to next star's data 
        dec modme2b+1           ; self-modifying code: point to next star's data 
        dec modme2b+1           ; self-modifying code: point to next star's data 
        
        dex                     ; TODO eliminate
        bne next_star
        
skip_shift_bg_chars
        
int_handler_wrapup      
        asl $d019               ; ACK interrupt (to re-enable it)       
        pla
        tay
        pla
        tax
        pla
        rti                     ; return from interrupt


;;; -----------------------------------------------------------------------------
;;; adapted from http://ocaoimh.ie/wp-content/uploads/2008/01/intro-to-programming-c64-demos.html#SECTION00086000000000000000
;;; -----------------------------------------------------------------------------
        
init_screen_for_raster_int

        lda #$1b                ; clear hi bit of raster int scanline (lo is at $d012) and set text mode
        sta $d011               
        ldx #$08                ; single-colour
        stx $d016               
        ldy #$14                ; screen at $0400, charset at $2000
        sty $d018               
        
install_raster_int
        sei                     ; turn off interrupts
        lda #$7f
        ldx #$01
        sta $dc0d               ; Turn off CIA 1 interrupts
        sta $dd0d               ; Turn off CIA 2 interrupts
        stx $d01a               ; Turn on raster interrupts

        lda #<int_handler       ; set raster interrupt vector
        ldx #>int_handler       
        sta $0314               
        stx $0315
        ldy #$80                ; set scanline on which to trigger interrupt
        sty $d012

        lda $dc0d               ; ACK CIA 1 interrupts
        lda $dd0d               ; ACK CIA 2 interrupts
        asl $d019               ; ACK VIC interrupts
        cli

        rts

message
        .null "(c) 2013 lemon/shinsetsu"

        
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
        .byte %00000000,%00000000,%00000000
        .byte %00000000,%00000000,%00000000
        .byte %00000000,%00000000,%00000000
        .byte %00000000,%00000000,%00000000
        .byte %00000000,%00000000,%00000000
        .byte %00000000,%00000000,%00000000
        .byte %11000000,%00000000,%00000000
        .byte %11100000,%00000000,%00000000
        .byte %11110000,%00000000,%00000000
        .byte %11111111,%11111100,%00000000
        .byte %11111111,%11111111,%11111111
        .byte %11111111,%11111111,%11111111
        .byte %01111111,%11111111,%11111100
        .byte %00001111,%11111111,%11000000
        .byte %00111111,%10000000,%00000000
        .byte %11111111,%11110000,%00000000
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
        .byte %00000000,%00000000,%00000000
        .byte %00000000,%00000000,%00000000
        .byte %00000000,%00000000,%00000000
        .byte %00000000,%00000000,%00000000
        .byte %00000000,%00000000,%00000000
        .byte %00000000,%00000000,%00000000
        .byte %00000000,%11111111,%11100000
		.byte %00000000,%11111111,%11100000
		.byte %00000000,%00000000,%00000000
		.byte %00000000,%00000000,%00000000

		
zero_page_data_src
		.byte $19, $79			; dummy, variable store
star_row_adrs_white_src
		.word $798
		.word $5e0
		.word $540
		.word $5e0
		.word $680
		.word $720
		.word $720
		.word $6f8
		.word $608
		.word $5b8
		.word $608
		.word $658
		.word $4c8
		.word $4f0
		
star_cols_white_src
		.byte 4
		.byte 5
		.byte 5
		.byte 8
		.byte 11
		.byte 7
		.byte 13
		.byte 8
		.byte 3
		.byte 25
		.byte 10
		.byte 5
		.byte 16
		.byte 20		
		
zero_page_data_src_end
		
star_char_1
		.screen "."

		
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
spr_spr_collision = $d01e

spr_size_bytes = 3*21

screen_size_x_px = 320
screen_ram = $0400
screen_ram_size = 40*25
color_ram = $d800		

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


;;; kernal routines
		
CHROUT  = $ffd2          
