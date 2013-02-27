//
//  yuv2rgb.s
//  HEVPlayer
//
//  Created by Shengbin Meng on 13-2-26.
//  Copyright (c) 2013年 Peking University. All rights reserved.
//


#ifdef __ARM_NEON__

/* Initial ARM Neon implementation of core YUV2RGB functions. */

.text
    .align 4
.global _yuv420_2_rgb8888_neon

/* Constants */
#define coef_y         D0
#define coef_v_r       D1
#define coef_u_g       D2
#define coef_v_g       D3
#define coef_u_b       D4
/* D5 is spare */
#define bias_r         Q3
#define bias_r_lo      D6
#define bias_r_hi      D7
#define bias_g         Q4
#define bias_g_lo      D8
#define bias_g_hi      D9
#define bias_b         Q5
#define bias_b_lo      D10
#define bias_b_hi      D11

/* Input data */
#define y_even         D24
#define y_odd          D26
#define u              D16 /*overlaps with Q8 - b_delta, but safe */
#define v              D17 /*overlaps with Q8 - b_delta, but safe */

/* Chrominance signal for whole 16x2 block */
#define r_delta        Q6
#define g_delta        Q7
#define b_delta        Q8

/* Current group of 8 pixels */
#define red            Q9
#define grn            Q10
#define blu            Q11
#define y_scale        Q15

/* output area, in the right order for interleaved output with VST4 */
#define blu8_e         D24 /* overlaps with y_even, but safe */
#define red8_e         D25
#define blu8_o         D26 /* overlaps with y_odd, but safe */
#define red8_o         D27
#define grn8_e         D28
#define alp8_e         D29
#define grn8_o         D30 /* overlaps with Q15 - y_scale, but safe */
#define alp8_o         D31 /* overlaps with Q15 - y_scale, but safe */

/* ARM registers */
#define rgb_t_ptr      r0
#define y_t_ptr        r1
#define u_ptr          r2
#define v_ptr          r3
#define width          r4
#define height         r5
#define y_pitch        r6
#define uv_pitch       r7
#define rgb_pitch      r8
#define count          r9
#define aligned_count  sl
#define rgb_b_ptr      fp
#define y_b_ptr        ip

/* Constants */
/* 8-bit constants can be loaded into vectors using VMOV */
#define C_Y_SCALE      74   /* Y scale , 74 */
#define C_V_RED        102  /* v -> red coefficient, 102 */
#define C_U_GREEN      25   /* u -> green , -25 */
#define C_V_GREEN      52   /* v -> green , -52 */
#define C_U_BLUE       129  /* u -> blue, +129 */

/* Coefficients */
coefficients:
coeff_bias_r:
.short  -14240  /* bias_r = 74 * (-16)                + (102 * -128) */
/*          -1,184                    + -13,056      */
coeff_bias_g:
.short    8672  /* bias_g = 74 * (-16) -  25 * (-128) - ( 52 * -128) */
/*          -1,184     -  -3200       - -6,656       */
coeff_bias_b:
.short  -17696  /* bias_b = 74 * (-16) + 129 * (-128)                */
/*          -1,184     + -16,512                     */
coeff_pad:
.short       0

/* void yuv420_2_rgb8888_neon(uint8_t       *dst_ptr,
 const uint8_t *y_ptr,
 const uint8_t *u_ptr,
 const uint8_t *v_ptr,
 int            width,
 int            height); */
_yuv420_2_rgb8888_neon:
/*  r0 = dst_ptr */
/*  r1 = y_ptr */
/*  r2 = u_ptr */
/*  r3 = v_ptr */
/*  <> = width */
/*  <> = height */
/*  <> = y_pitch */
/*  <> = uv_pitch */
/*  <> = rgb_pitch */
push            {r4-r12, lr}         /* 10 words */
vpush           {q4-q7}              /* 4q -> 16 words */

ldr             width,  [sp, #26*4]
ldr             height, [sp, #27*4]
ldr             y_pitch, [sp, #28*4]
ldr             uv_pitch, [sp, #29*4]
ldr             rgb_pitch, [sp, #30*4]
adr             lr, coefficients

/* we can't cope with a width less than 16. check for that. */
cmp             width, #16
vpoplt          {q4-q7}
poplt           {r4-r12, pc}

/* load up vectors containing the bias values. */
vld1.s16        {bias_r_lo[], bias_r_hi[]}, [lr]!
vld1.s16        {bias_g_lo[], bias_g_hi[]}, [lr]!
vld1.s16        {bias_b_lo[], bias_b_hi[]}, [lr]!

/* build coefficient vectors containing the same value in each element. */
vmov.u8         coef_y, #C_Y_SCALE
vmov.u8         coef_v_r, #C_V_RED
vmov.u8         coef_u_g, #C_U_GREEN
vmov.u8         coef_v_g, #C_V_GREEN
vmov.u8         coef_u_b, #C_U_BLUE

loop_v_420:
add             y_b_ptr, y_t_ptr, y_pitch
add             rgb_b_ptr, rgb_t_ptr, rgb_pitch
mov             aligned_count, width

/* if width is not an integer multiple of 16, run the
 first pass through the loop with the correct number
 of pixels to correct the size for the remaining loops. */
ands            count, width, #15
/* if we're already aligned (i.e. count is now 0), set count
 to 16 to run the first loop as normal. */
moveq           count, #16

loop_h_420:
/*****************************/
/* common code for both rows */
/*****************************/
/* load u and v. */
vld1.u8         v, [v_ptr]
add             v_ptr, count, asr #1
vld1.u8         u, [u_ptr]
add             u_ptr, count, asr #1

/* calculate contribution from chrominance signals. */
vmull.u8        r_delta, v, coef_v_r
vmull.u8        g_delta, u, coef_u_g
vmlal.u8        g_delta, v, coef_v_g
vmull.u8        b_delta, u, coef_u_b

/* add bias. */
vadd.s16        r_delta, r_delta, bias_r
vsub.s16        g_delta, bias_g, g_delta
vadd.s16        b_delta, b_delta, bias_b

/* attempt to preload the next set of u and v input data, for
 better performance. */
pld             [v_ptr]
pld             [u_ptr]

/***********/
/* top row */
/***********/
/* top row: load 16 pixels of y, even and odd. */
vld2.u8         {y_even, y_odd}, [y_t_ptr], count

/* top row, even: combine luminance and chrominance. */
vmull.u8        y_scale, y_even, coef_y
vqadd.s16       red, y_scale, r_delta
vqadd.s16       grn, y_scale, g_delta
vqadd.s16       blu, y_scale, b_delta

/* top row, even: set up alpha data. */
vmov.u8         alp8_e, #0xff

/* top row, even: clamp, rescale and clip colour components to 8 bits. */
vqrshrun.s16    red8_e, red, #6
vqrshrun.s16    grn8_e, grn, #6
vqrshrun.s16    blu8_e, blu, #6

/* top row: attempt to preload the next set of y data, for
 better performance. */
pld             [y_t_ptr]

/* top row, even: interleave the colour and alpha components
 ready for storage. */
vzip.u8         red8_e, alp8_e
vzip.u8         blu8_e, grn8_e

/* top row, odd: combine luminance and chrominance. */
vmull.u8        y_scale, y_odd, coef_y
vqadd.s16       red, y_scale, r_delta
vqadd.s16       grn, y_scale, g_delta
vqadd.s16       blu, y_scale, b_delta

/* top row, odd: set up alpha data. */
vmov.u8         alp8_o, #0xff

/* top row, odd: clamp, rescale and clip colour components to 8 bits. */
vqrshrun.s16    red8_o, red, #6
vqrshrun.s16    blu8_o, blu, #6
vqrshrun.s16    grn8_o, grn, #6

/* top row, odd: interleave the colour and alpha components
 ready for storage. */
vzip.u8         red8_o, alp8_o
vzip.u8         blu8_o, grn8_o

/* top row: store 16 pixels of argb32, interleaving even and
 odd. */
vst4.u16        {blu8_e, red8_e, blu8_o, red8_o}, [rgb_t_ptr]
add             rgb_t_ptr, count, lsl #1
vst4.u16        {grn8_e, alp8_e, grn8_o, alp8_o}, [rgb_t_ptr]
add             rgb_t_ptr, count, lsl #1

/**************/
/* bottom row */
/**************/
/* bottom row: load 16 pixels of y, even and odd. */
vld2.u8         {y_even, y_odd}, [y_b_ptr], count

/* bottom row, even: combine luminance and chrominance. */
vmull.u8        y_scale, y_even, coef_y
vqadd.s16       red, y_scale, r_delta
vqadd.s16       grn, y_scale, g_delta
vqadd.s16       blu, y_scale, b_delta

/* bottom row, even: set up alpha data. */
vmov.u8         alp8_e, #0xff

/* bottom row, even: clamp, rescale and clip colour components to 8 bits. */
vqrshrun.s16    red8_e, red, #6
vqrshrun.s16    blu8_e, blu, #6
vqrshrun.s16    grn8_e, grn, #6

/* bottom row: attempt to preload the next set of y data, for
 better performance. */
pld             [y_b_ptr]

/* bottom row, even: interleave the colour and alpha components
 ready for storage. */
vzip.u8         red8_e, alp8_e
vzip.u8         blu8_e, grn8_e

/* bottom row, odd: combine luminance and chrominance. */
vmull.u8        y_scale, y_odd, coef_y
vqadd.s16       red, y_scale, r_delta
vqadd.s16       grn, y_scale, g_delta
vqadd.s16       blu, y_scale, b_delta

/* bottom row, odd: set up alpha data. */
vmov.u8         alp8_o, #0xff

/* bottom row, odd: clamp, rescale and clip colour components to 8 bits. */
vqrshrun.s16    red8_o, red, #6
vqrshrun.s16    blu8_o, blu, #6
vqrshrun.s16    grn8_o, grn, #6

/* bottom row, odd: interleave the colour and alpha components
 ready for storage. */
vzip.u8         red8_o, alp8_o
vzip.u8         blu8_o, grn8_o

/* have we reached the end of the row yet? */
subs            aligned_count, aligned_count, count

/* bottom row: store 16 pixels of argb32, interleaving even and
 odd. */
vst4.u16        {blu8_e, red8_e, blu8_o, red8_o}, [rgb_b_ptr]
add             rgb_b_ptr, count, lsl #1
vst4.u16        {grn8_e, alp8_e, grn8_o, alp8_o}, [rgb_b_ptr]
add             rgb_b_ptr, count, lsl #1

/* on the second (and subsequent) passes through this code,
 we'll always be working on 16 pixels at once. */
mov             count, #16
bgt             loop_h_420

/* update pointers for new row of data. */
sub             rgb_t_ptr, width, lsl #2
sub             y_t_ptr, width
sub             u_ptr, width, asr #1
sub             v_ptr, width, asr #1
add             rgb_t_ptr, rgb_pitch, lsl #1
add             y_t_ptr, y_pitch, lsl #1
add             u_ptr, uv_pitch
add             v_ptr, uv_pitch

/* have we reached the bottom row yet? */
subs            height, height, #2
bgt             loop_v_420

vpop            {q4-q7}
pop             {r4-r12, pc}

#endif /* __ARM_NEON__ */
