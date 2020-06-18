/**
 * Author......: See docs/credits.txt
 * License.....: MIT
 */

#define NEW_SIMD_CODE

#ifdef KERNEL_STATIC
#include "inc_vendor.h"
#include "inc_types.h"
#include "inc_platform.cl"
#include "inc_common.cl"
#include "inc_simd.cl"
#include "inc_hash_md5.cl"
#include "inc_hash_sha1.cl"
#endif

#if   VECT_SIZE == 1
#define uint_to_hex_lower8_le(i) make_u32x (l_bin2asc[(i)])
#elif VECT_SIZE == 2
#define uint_to_hex_lower8_le(i) make_u32x (l_bin2asc[(i).s0], l_bin2asc[(i).s1])
#elif VECT_SIZE == 4
#define uint_to_hex_lower8_le(i) make_u32x (l_bin2asc[(i).s0], l_bin2asc[(i).s1], l_bin2asc[(i).s2], l_bin2asc[(i).s3])
#elif VECT_SIZE == 8
#define uint_to_hex_lower8_le(i) make_u32x (l_bin2asc[(i).s0], l_bin2asc[(i).s1], l_bin2asc[(i).s2], l_bin2asc[(i).s3], l_bin2asc[(i).s4], l_bin2asc[(i).s5], l_bin2asc[(i).s6], l_bin2asc[(i).s7])
#elif VECT_SIZE == 16
#define uint_to_hex_lower8_le(i) make_u32x (l_bin2asc[(i).s0], l_bin2asc[(i).s1], l_bin2asc[(i).s2], l_bin2asc[(i).s3], l_bin2asc[(i).s4], l_bin2asc[(i).s5], l_bin2asc[(i).s6], l_bin2asc[(i).s7], l_bin2asc[(i).s8], l_bin2asc[(i).s9], l_bin2asc[(i).sa], l_bin2asc[(i).sb], l_bin2asc[(i).sc], l_bin2asc[(i).sd], l_bin2asc[(i).se], l_bin2asc[(i).sf])
#endif

KERNEL_FQ void m21100_mxx (KERN_ATTR_VECTOR ())
{
  /**
   * modifier
   */

  const u64 gid = get_global_id (0);
  const u64 lid = get_local_id (0);
  const u64 lsz = get_local_size (0);

  /**
   * bin2asc table
   */

  LOCAL_VK u32 l_bin2asc[256];

  for (u32 i = lid; i < 256; i += lsz)
  {
    const u32 i0 = (i >> 0) & 15;
    const u32 i1 = (i >> 4) & 15;

    l_bin2asc[i] = ((i0 < 10) ? '0' + i0 : 'a' - 10 + i0) << 0
                 | ((i1 < 10) ? '0' + i1 : 'a' - 10 + i1) << 8;
  }

  SYNC_THREADS ();

  if (gid >= gid_max) return;

  /**
   * base
   */

  const u32 pw_len = pws[gid].pw_len;

  u32x w[64] = { 0 };

  for (u32 i = 0, idx = 0; i < pw_len; i += 4, idx += 1)
  {
    w[idx] = pws[gid].i[idx];
  }

  const u32 salt_len = salt_bufs[salt_pos].salt_len;

  u32 s[64] = { 0 };

  for (u32 i = 0, idx = 0; i < salt_len; i += 4, idx += 1)
  {
    s[idx] = salt_bufs[salt_pos].salt_buf[idx];
  }

  /**
   * loop
   */

  u32x _w0[4];
  u32x _w1[4];
  u32x _w2[4];
  u32x _w3[4];

  u32x w0l = w[0];

  for (u32 il_pos = 0; il_pos < il_cnt; il_pos += VECT_SIZE)
  {
    const u32x w0r = words_buf_r[il_pos / VECT_SIZE];

    const u32x w0 = w0l | w0r;

    w[0] = w0;

    md5_ctx_vector_t ctx0;

    md5_init_vector (&ctx0);

    md5_update_vector (&ctx0, w, pw_len);

    md5_update_vector (&ctx0, s, salt_len);

    md5_final_vector (&ctx0);

    const u32x a = ctx0.h[0];
    const u32x b = ctx0.h[1];
    const u32x c = ctx0.h[2];
    const u32x d = ctx0.h[3];

    sha1_ctx_vector_t ctx;

    sha1_init_vector (&ctx);

    _w0[0] = uint_to_hex_lower8_le ((a >>  8) & 255) <<  0
           | uint_to_hex_lower8_le ((a >>  0) & 255) << 16;
    _w0[1] = uint_to_hex_lower8_le ((a >> 24) & 255) <<  0
           | uint_to_hex_lower8_le ((a >> 16) & 255) << 16;
    _w0[2] = uint_to_hex_lower8_le ((b >>  8) & 255) <<  0
           | uint_to_hex_lower8_le ((b >>  0) & 255) << 16;
    _w0[3] = uint_to_hex_lower8_le ((b >> 24) & 255) <<  0
           | uint_to_hex_lower8_le ((b >> 16) & 255) << 16;
    _w1[0] = uint_to_hex_lower8_le ((c >>  8) & 255) <<  0
           | uint_to_hex_lower8_le ((c >>  0) & 255) << 16;
    _w1[1] = uint_to_hex_lower8_le ((c >> 24) & 255) <<  0
           | uint_to_hex_lower8_le ((c >> 16) & 255) << 16;
    _w1[2] = uint_to_hex_lower8_le ((d >>  8) & 255) <<  0
           | uint_to_hex_lower8_le ((d >>  0) & 255) << 16;
    _w1[3] = uint_to_hex_lower8_le ((d >> 24) & 255) <<  0
           | uint_to_hex_lower8_le ((d >> 16) & 255) << 16;

    _w2[0] = 0;
    _w2[1] = 0;
    _w2[2] = 0;
    _w2[3] = 0;
    _w3[0] = 0;
    _w3[1] = 0;
    _w3[2] = 0;
    _w3[3] = 0;

    sha1_update_vector_64 (&ctx, _w0, _w1, _w2, _w3, 32);

    sha1_final_vector (&ctx);

    const u32x r0 = ctx.h[DGST_R0];
    const u32x r1 = ctx.h[DGST_R1];
    const u32x r2 = ctx.h[DGST_R2];
    const u32x r3 = ctx.h[DGST_R3];

    COMPARE_M_SIMD (r0, r1, r2, r3);
  }
}

KERNEL_FQ void m21100_sxx (KERN_ATTR_VECTOR ())
{
  /**
   * modifier
   */

  const u64 gid = get_global_id (0);
  const u64 lid = get_local_id (0);
  const u64 lsz = get_local_size (0);

  /**
   * bin2asc table
   */

  LOCAL_VK u32 l_bin2asc[256];

  for (u32 i = lid; i < 256; i += lsz)
  {
    const u32 i0 = (i >> 0) & 15;
    const u32 i1 = (i >> 4) & 15;

    l_bin2asc[i] = ((i0 < 10) ? '0' + i0 : 'a' - 10 + i0) << 0
                 | ((i1 < 10) ? '0' + i1 : 'a' - 10 + i1) << 8;
  }

  SYNC_THREADS ();

  if (gid >= gid_max) return;

  /**
   * digest
   */

  const u32 search[4] =
  {
    digests_buf[digests_offset].digest_buf[DGST_R0],
    digests_buf[digests_offset].digest_buf[DGST_R1],
    digests_buf[digests_offset].digest_buf[DGST_R2],
    digests_buf[digests_offset].digest_buf[DGST_R3]
  };

  /**
   * base
   */

  const u32 pw_len = pws[gid].pw_len;

  u32x w[64] = { 0 };

  for (u32 i = 0, idx = 0; i < pw_len; i += 4, idx += 1)
  {
    w[idx] = pws[gid].i[idx];
  }

  const u32 salt_len = salt_bufs[salt_pos].salt_len;

  u32 s[64] = { 0 };

  for (u32 i = 0, idx = 0; i < salt_len; i += 4, idx += 1)
  {
    s[idx] = salt_bufs[salt_pos].salt_buf[idx];
  }

  /**
   * loop
   */

  u32x _w0[4];
  u32x _w1[4];
  u32x _w2[4];
  u32x _w3[4];

  u32x w0l = w[0];

  for (u32 il_pos = 0; il_pos < il_cnt; il_pos += VECT_SIZE)
  {
    const u32x w0r = words_buf_r[il_pos / VECT_SIZE];

    const u32x w0 = w0l | w0r;

    w[0] = w0;

    md5_ctx_vector_t ctx0;

    md5_init_vector (&ctx0);

    md5_update_vector (&ctx0, w, pw_len);

    md5_update_vector (&ctx0, s, salt_len);

    md5_final_vector (&ctx0);

    const u32x a = ctx0.h[0];
    const u32x b = ctx0.h[1];
    const u32x c = ctx0.h[2];
    const u32x d = ctx0.h[3];

    sha1_ctx_vector_t ctx;

    sha1_init_vector (&ctx);

    _w0[0] = uint_to_hex_lower8_le ((a >>  8) & 255) <<  0
           | uint_to_hex_lower8_le ((a >>  0) & 255) << 16;
    _w0[1] = uint_to_hex_lower8_le ((a >> 24) & 255) <<  0
           | uint_to_hex_lower8_le ((a >> 16) & 255) << 16;
    _w0[2] = uint_to_hex_lower8_le ((b >>  8) & 255) <<  0
           | uint_to_hex_lower8_le ((b >>  0) & 255) << 16;
    _w0[3] = uint_to_hex_lower8_le ((b >> 24) & 255) <<  0
           | uint_to_hex_lower8_le ((b >> 16) & 255) << 16;
    _w1[0] = uint_to_hex_lower8_le ((c >>  8) & 255) <<  0
           | uint_to_hex_lower8_le ((c >>  0) & 255) << 16;
    _w1[1] = uint_to_hex_lower8_le ((c >> 24) & 255) <<  0
           | uint_to_hex_lower8_le ((c >> 16) & 255) << 16;
    _w1[2] = uint_to_hex_lower8_le ((d >>  8) & 255) <<  0
           | uint_to_hex_lower8_le ((d >>  0) & 255) << 16;
    _w1[3] = uint_to_hex_lower8_le ((d >> 24) & 255) <<  0
           | uint_to_hex_lower8_le ((d >> 16) & 255) << 16;

    _w2[0] = 0;
    _w2[1] = 0;
    _w2[2] = 0;
    _w2[3] = 0;
    _w3[0] = 0;
    _w3[1] = 0;
    _w3[2] = 0;
    _w3[3] = 0;

    sha1_update_vector_64 (&ctx, _w0, _w1, _w2, _w3, 32);

    sha1_final_vector (&ctx);

    const u32x r0 = ctx.h[DGST_R0];
    const u32x r1 = ctx.h[DGST_R1];
    const u32x r2 = ctx.h[DGST_R2];
    const u32x r3 = ctx.h[DGST_R3];

    COMPARE_S_SIMD (r0, r1, r2, r3);
  }
}
