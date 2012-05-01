; Mouse flasher
; MCU: attiny25

#include <avr/io.h>

PWM_MAX = 127

isreg = 0
zero = 1

tmp0 = 16
tmp1 = 17

icall0 = 18
itmp0 = 19
itmp1 = 20

ival0 = 21
ival1 = 22
ival2 = 23
ival3 = 24

icurcycle = 25
idir = 26 ; bitflag

; address offset (-0x20)
#define IO(_IO) _SFR_IO_ADDR(_IO)

.section .text


;;; ======================
.macro INIT_TIMER0
    ; set CTC mode
    ldi itmp0, 1<<WGM01
    out IO(TCCR0A), itmp0
    ; set compare value
    ldi itmp0, 100
    out IO(OCR0A), itmp0
    ; enable on compare match interrupt
    ldi itmp0, 1<<OCIE0A
    out IO(TIMSK), itmp0
    ; set prescaler and start timer
    ldi itmp0, 1<<CS00 ; prescaler value (0)
    out IO(TCCR0B), itmp0
.endm


;;; ======================
.macro INIT_TIMER1
    ; set compare value, 61 tick second at prescaler 64, at 1Mhz
    ldi itmp0, 255
    out IO(OCR1A), itmp0
    ; set CTC mode and prescaler 64, 15625hz at 1Mhz
    ldi itmp0, (1<<CTC1) | (1<<CS12) | (1<<CS11) | (1<<CS10)
    out IO(TCCR1), itmp0
    ; enable on compare match interrupt
    in itmp0, IO(TIMSK)
    ori itmp0, 1<<OCIE1A
    out IO(TIMSK), itmp0
.endm


;;; ======================
.macro INIT
    ; init outputs
    ldi tmp0, (1<<PB0) | (1<<PB1) | (1<<PB2) | (1<<PB3)
    ldi tmp1, (1<<DDB0) | (1<<DDB1) | (1<<DDB2) | (1<<DDB3)
    out IO(PORTB), tmp0
    out IO(DDRB), tmp1
    
    ; init value
    ldi ival0, (PWM_MAX/4) * 0
    ldi ival1, (PWM_MAX/4) * 1
    ldi ival2, (PWM_MAX/4) * 2
    ldi ival3, (PWM_MAX/4) * 3
    ldi icurcycle, 0

    sei ; enable interupt
    INIT_TIMER0
    INIT_TIMER1
.endm


;;; ======================
;;; params: icall0 in: value from 0 to pwm table size - 1, out: fetched value
;;; ======================
.macro FETCH_PWM_TABLE
    ldi ZL, lo8(pwm_table)
    ldi ZH, hi8(pwm_table)
    add ZL, icall0
    adc ZH, zero
    lpm icall0, Z
.endm


;;; ======================
    .global main
main:
    INIT
.loop:
    rjmp .loop


;;; ======================
;;; PWM interrupt
;;; ======================
    .global TIMER0_COMPA_vect
TIMER0_COMPA_vect:
    in isreg, IO(SREG)

    inc icurcycle
    cpi icurcycle, PWM_MAX
    brne .skipcyclereset
    clr icurcycle
.skipcyclereset:

    ;;; ======================
    .macro PWM_UPDATE_OUTPUT outval, outnum
        mov icall0, \outval
        FETCH_PWM_TABLE
        cp icall0, icurcycle
        brsh 1f

        ; set off
        cbi IO(PORTB), \outnum
        rjmp 11f

    1:  ; set on
        sbi IO(PORTB), \outnum
    11:
    .endm
    ;;; ======================

    PWM_UPDATE_OUTPUT ival0, PB0
    PWM_UPDATE_OUTPUT ival1, PB1
    PWM_UPDATE_OUTPUT ival2, PB2
    PWM_UPDATE_OUTPUT ival3, PB3

    out IO(SREG), isreg
    reti


;;; ======================
;;; update value interrupt
;;; ======================
    .global TIMER1_COMPA_vect
TIMER1_COMPA_vect:
    in isreg, IO(SREG)

    ;;; ======================
    .macro UPDATE_VALUE val, num
    ;;; switch direction on boundaries

        ; check min
        tst \val
        brne 1f

        ; set new direction
        ser itmp0
        bst itmp0, \num
        bld idir, \num
        rjmp 2f

    1:  ; check max
        cpi \val, PWM_MAX
        brne 2f

        ; set new direction
        clr itmp0
        bst itmp0, \num
        bld idir, \num
    2:

    ;;; update
        sbrc idir, \num
        rjmp 3f

        dec \val
        rjmp 33f

    3:  inc \val 
    33:
    .endm
    ;;; ======================

    UPDATE_VALUE ival0, 0
    UPDATE_VALUE ival1, 1
    UPDATE_VALUE ival2, 2
    UPDATE_VALUE ival3, 3

    out IO(SREG), isreg
    reti


;;; ======================
pwm_table:
    .word 0x0001
    .word 0x0101
    .word 0x0101
    .word 0x0101
    .word 0x0101
    .word 0x0101
    .word 0x0101
    .word 0x0101
    .word 0x0102
    .word 0x0202
    .word 0x0202
    .word 0x0202
    .word 0x0202
    .word 0x0303
    .word 0x0303
    .word 0x0303
    .word 0x0304
    .word 0x0404
    .word 0x0405
    .word 0x0505
    .word 0x0505
    .word 0x0606
    .word 0x0607
    .word 0x0707
    .word 0x0708
    .word 0x0809
    .word 0x090a
    .word 0x0a0a
    .word 0x0b0b
    .word 0x0c0d
    .word 0x0d0e
    .word 0x0e0f
    .word 0x0f10
    .word 0x1112
    .word 0x1314
    .word 0x1415
    .word 0x1617
    .word 0x181a
    .word 0x1b1c
    .word 0x1d1e
    .word 0x1f21
    .word 0x2324
    .word 0x2628
    .word 0x292b
    .word 0x2d2f
    .word 0x3134
    .word 0x3638
    .word 0x3b3d
    .word 0x3f43
    .word 0x4649
    .word 0x4c50
    .word 0x5356
    .word 0x5a5e
    .word 0x6368
    .word 0x6c71
    .word 0x767a
    .word 0x7f86
    .word 0x8c93
    .word 0x99a0
    .word 0xa7ad
    .word 0xb4bd
    .word 0xc6d0
    .word 0xd9e2
    .word 0xecff
