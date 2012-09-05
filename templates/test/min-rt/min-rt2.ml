(****************************************************************)
(*                                                              *)
(* Ray Tracing Program for (Mini) Objective Caml                *)
(*                                                              *)
(* Original Program by Ryoji Kawamichi                          *)
(* Arranged for Chez Scheme by Motohico Nanano                  *)
(* Arranged for Objective Caml by Y.Oiwa and E.Sumii            *)
(* Added diffuse ray tracer by Y.Sugawara                       *)
(*                                                              *)
(****************************************************************)

(*NOMINCAML open MiniMLRuntime;;*)
(*NOMINCAML open Globals;;*)
(*(*MINCAML*) let true = 1 in 
(*MINCAML*) let false = 0 in *)
(*(*MINCAML*) let rec xor x y = if x then not y else y in
*)
(******************************************************************************
   ¥æ¡Œ¥Æ¥£¥ê¥Æ¥£¡Œ
 *****************************************************************************)

(* Éä¹æ *)
let rec sgn x =
  if fiszero x then 0.0
  else if fispos x then 1.0
  else -1.0
in

(* Ÿò·ïÉÕ€­Éä¹æÈ¿ÅŸ *)
let rec fneg_cond cond x =
  if cond then x else fneg x
in

(* (x+y) mod 5 *)
let rec add_mod5 x y =
  let sum = x + y in
  if sum >= 5 then sum - 5 else sum
in

(******************************************************************************
   ¥Ù¥¯¥È¥ëÁàºî€Î€¿€á€Î¥×¥ê¥ß¥Æ¥£¥Ö
 *****************************************************************************)

(*
let rec vecprint v =
  (o_param_abc m) inFormat.eprintf "(%f %f %f)" v.(0) v.(1) v.(2)
in
*)

(* ÃÍÂåÆþ *)
let rec vecset v x y z =
  v.(0) <- x;
  v.(1) <- y;
  v.(2) <- z
in

(* Æ±€žÃÍ€ÇËä€á€ë *)
let rec vecfill v elem =
  v.(0) <- elem;
  v.(1) <- elem;
  v.(2) <- elem
in

(* ÎíœéŽü²œ *)
let rec vecbzero v =
  vecfill v 0.0
in

(* ¥³¥Ô¡Œ *)
let rec veccpy dest src = 
  dest.(0) <- src.(0);
  dest.(1) <- src.(1);
  dest.(2) <- src.(2)
in

(* µ÷Î¥€ÎŒ«Ÿè *)
let rec vecdist2 p q = 
  fsqr (p.(0) -. q.(0)) +. fsqr (p.(1) -. q.(1)) +. fsqr (p.(2) -. q.(2))
in

(* Àµµ¬²œ ¥Œ¥í³ä€ê¥Á¥§¥Ã¥¯Ìµ€· *)
let rec vecunit v = 
  let il = 1.0 /. sqrt(fsqr v.(0) +. fsqr v.(1) +. fsqr v.(2)) in
  v.(0) <- v.(0) *. il;
  v.(1) <- v.(1) *. il;
  v.(2) <- v.(2) *. il
in

(* Éä¹æÉÕÀµµ¬²œ ¥Œ¥í³ä¥Á¥§¥Ã¥¯*)
let rec vecunit_sgn v inv =
  let l = sqrt (fsqr v.(0) +. fsqr v.(1) +. fsqr v.(2)) in
  let il = if fiszero l then 1.0 else if inv then -1.0 /. l else 1.0 /. l in
  v.(0) <- v.(0) *. il;
  v.(1) <- v.(1) *. il;
  v.(2) <- v.(2) *. il
in

(* ÆâÀÑ *)
let rec veciprod v w =
  v.(0) *. w.(0) +. v.(1) *. w.(1) +. v.(2) *. w.(2)
in

(* ÆâÀÑ °ú¿ô·ÁŒ°€¬°Û€Ê€ëÈÇ *)
let rec veciprod2 v w0 w1 w2 =
  v.(0) *. w0 +. v.(1) *. w1 +. v.(2) *. w2
in

(* ÊÌ€Ê¥Ù¥¯¥È¥ë€ÎÄê¿ôÇÜ€ò²Ã»» *)
let rec vecaccum dest scale v =
  dest.(0) <- dest.(0) +. scale *. v.(0);
  dest.(1) <- dest.(1) +. scale *. v.(1);
  dest.(2) <- dest.(2) +. scale *. v.(2)
in

(* ¥Ù¥¯¥È¥ë€ÎÏÂ *)
let rec vecadd dest v =
  dest.(0) <- dest.(0) +. v.(0);
  dest.(1) <- dest.(1) +. v.(1);
  dest.(2) <- dest.(2) +. v.(2)
in

(* ¥Ù¥¯¥È¥ëÍ×ÁÇÆ±»Î€ÎÀÑ *)
let rec vecmul dest v =
  dest.(0) <- dest.(0) *. v.(0);
  dest.(1) <- dest.(1) *. v.(1);
  dest.(2) <- dest.(2) *. v.(2)
in

(* ¥Ù¥¯¥È¥ë€òÄê¿ôÇÜ *)
let rec vecscale dest scale =
  dest.(0) <- dest.(0) *. scale; 
  dest.(1) <- dest.(1) *. scale; 
  dest.(2) <- dest.(2) *. scale
in

(* ÂŸ€Î£²¥Ù¥¯¥È¥ë€ÎÍ×ÁÇÆ±»Î€ÎÀÑ€ò·×»»€·²Ã»» *)
let rec vecaccumv dest v w =
  dest.(0) <- dest.(0) +. v.(0) *. w.(0);
  dest.(1) <- dest.(1) +. v.(1) *. w.(1);
  dest.(2) <- dest.(2) +. v.(2) *. w.(2)
in

(******************************************************************************
   ¥ª¥Ö¥ž¥§¥¯¥È¥Ç¡Œ¥¿¹œÂ€€Ø€Î¥¢¥¯¥»¥¹ŽØ¿ô
 *****************************************************************************)

(* ¥Æ¥¯¥¹¥Á¥ãŒï 0:Ìµ€· 1:»ÔŸŸÌÏÍÍ 2:ŒÊÌÏÍÍ 3:Æ±¿Ž±ßÌÏÍÍ 4:ÈÃÅÀ*)
let rec o_texturetype m = 
  let (m_tex, xm_shape, xm_surface, xm_isrot, 
       xm_abc, xm_xyz, 
       xm_invert, xm_surfparams, xm_color,
       xm_rot123, xm_ctbl) = m 
  in
  m_tex
in

(* ÊªÂÎ€Î·ÁŸõ 0:ÄŸÊýÂÎ 1:Ê¿ÌÌ 2:ÆóŒ¡¶ÊÌÌ 3:±ß¿í *)
let rec o_form m = 
  let (xm_tex, m_shape, xm_surface, xm_isrot, 
       xm_abc, xm_xyz, 
       xm_invert, xm_surfparams, xm_color,
       xm_rot123, xm_ctbl) = m 
  in
  m_shape
in

(* È¿ŒÍÆÃÀ­ 0:³È»¶È¿ŒÍ€Î€ß 1:³È»¶¡ÜÈóŽ°ÁŽ¶ÀÌÌÈ¿ŒÍ 2:³È»¶¡ÜŽ°ÁŽ¶ÀÌÌÈ¿ŒÍ *)
let rec o_reflectiontype m = 
  let (xm_tex, xm_shape, m_surface, xm_isrot, 
       xm_abc, xm_xyz, 
       xm_invert, xm_surfparams, xm_color,
       xm_rot123, xm_ctbl) = m 
  in
  m_surface
in

(* ¶ÊÌÌ€Î³°ÂŠ€¬¿¿€«€É€Š€«€Î¥Õ¥é¥° true:³°ÂŠ€¬¿¿ false:ÆâÂŠ€¬¿¿ *)
let rec o_isinvert m = 
  let (xm_tex, xm_shape, xm_surface, xm_isrot, 
       xm_abc, xm_xyz, 
       m_invert, xm_surfparams, xm_color,
       xm_rot123, xm_ctbl) = m in
  m_invert
in

(* ²óÅŸ€ÎÍ­Ìµ true:²óÅŸ€¢€ê false:²óÅŸÌµ€· 2Œ¡¶ÊÌÌ€È±ß¿í€Î€ßÍ­žú *)
let rec o_isrot m = 
  let (xm_tex, xm_shape, xm_surface, m_isrot, 
       xm_abc, xm_xyz, 
       xm_invert, xm_surfparams, xm_color,
       xm_rot123, xm_ctbl) = m in
  m_isrot
in

(* ÊªÂÎ·ÁŸõ€Î a¥Ñ¥é¥á¡Œ¥¿ *)
let rec o_param_a m = 
  let (xm_tex, xm_shape, xm_surface, xm_isrot, 
       m_abc, xm_xyz, 
       xm_invert, xm_surfparams, xm_color,
       xm_rot123, xm_ctbl) = m 
  in
  m_abc.(0)
in

(* ÊªÂÎ·ÁŸõ€Î b¥Ñ¥é¥á¡Œ¥¿ *)
let rec o_param_b m = 
  let (xm_tex, xm_shape, xm_surface, xm_isrot, 
       m_abc, xm_xyz, 
       xm_invert, xm_surfparams, xm_color,
       xm_rot123, xm_ctbl) = m 
  in
  m_abc.(1)
in

(* ÊªÂÎ·ÁŸõ€Î c¥Ñ¥é¥á¡Œ¥¿ *)
let rec o_param_c m = 
  let (xm_tex, xm_shape, xm_surface, xm_isrot, 
       m_abc, xm_xyz, 
       xm_invert, xm_surfparams, xm_color,
       xm_rot123, xm_ctbl) = m 
  in
  m_abc.(2)
in

(* ÊªÂÎ·ÁŸõ€Î abc¥Ñ¥é¥á¡Œ¥¿ *)
let rec o_param_abc m = 
  let (xm_tex, xm_shape, xm_surface, xm_isrot, 
       m_abc, xm_xyz, 
       xm_invert, xm_surfparams, xm_color,
       xm_rot123, xm_ctbl) = m 
  in
  m_abc
in

(* ÊªÂÎ€ÎÃæ¿ŽxºÂÉž *)
let rec o_param_x m = 
  let (xm_tex, xm_shape, xm_surface, xm_isrot, 
       xm_abc, m_xyz, 
       xm_invert, xm_surfparams, xm_color,
       xm_rot123, xm_ctbl) = m 
  in
  m_xyz.(0)
in

(* ÊªÂÎ€ÎÃæ¿ŽyºÂÉž *)
let rec o_param_y m = 
  let (xm_tex, xm_shape, xm_surface, xm_isrot, 
       xm_abc, m_xyz,
       xm_invert, xm_surfparams, xm_color,
       xm_rot123, xm_ctbl) = m 
  in
  m_xyz.(1)
in

(* ÊªÂÎ€ÎÃæ¿ŽzºÂÉž *)
let rec o_param_z m = 
  let (xm_tex, xm_shape, xm_surface, xm_isrot, 
       xm_abc, m_xyz,
       xm_invert, xm_surfparams, xm_color,
       xm_rot123, xm_ctbl) = m 
  in
  m_xyz.(2)
in

(* ÊªÂÎ€Î³È»¶È¿ŒÍÎš 0.0 -- 1.0 *)
let rec o_diffuse m = 
  let (xm_tex, xm_shape, xm_surface, xm_isrot, 
       xm_abc, xm_xyz, 
       xm_invert, m_surfparams, xm_color,
       xm_rot123, xm_ctbl) = m 
  in
  m_surfparams.(0)
in

(* ÊªÂÎ€ÎÉÔŽ°ÁŽ¶ÀÌÌÈ¿ŒÍÎš 0.0 -- 1.0 *)
let rec o_hilight m = 
  let (xm_tex, xm_shape, xm_surface, xm_isrot, 
       xm_abc, xm_xyz, 
       xm_invert, m_surfparams, xm_color,
       xm_rot123, xm_ctbl) = m 
  in
  m_surfparams.(1)
in

(* ÊªÂÎ¿§€Î RÀ®Ê¬ *)
let rec o_color_red m = 
  let (xm_tex, xm_shape, m_surface, xm_isrot, 
       xm_abc, xm_xyz, 
       xm_invert, xm_surfparams, m_color,
       xm_rot123, xm_ctbl) = m 
  in
  m_color.(0)
in

(* ÊªÂÎ¿§€Î GÀ®Ê¬ *)
let rec o_color_green m = 
  let (xm_tex, xm_shape, m_surface, xm_isrot, 
       xm_abc, xm_xyz, 
       xm_invert, xm_surfparams, m_color,
       xm_rot123, xm_ctbl) = m 
  in
  m_color.(1)
in

(* ÊªÂÎ¿§€Î BÀ®Ê¬ *)
let rec o_color_blue m = 
  let (xm_tex, xm_shape, m_surface, xm_isrot, 
       xm_abc, xm_xyz, 
       xm_invert, xm_surfparams, m_color,
       xm_rot123, xm_ctbl) = m 
  in
  m_color.(2)
in

(* ÊªÂÎ€Î¶ÊÌÌÊýÄøŒ°€Î y*z¹à€Î·ž¿ô 2Œ¡¶ÊÌÌ€È±ß¿í€Ç¡¢²óÅŸ€¬€¢€ëŸì¹ç€Î€ß *)
let rec o_param_r1 m = 
  let (xm_tex, xm_shape, xm_surface, xm_isrot, 
       xm_abc, xm_xyz, 
       xm_invert, xm_surfparams, xm_color,
       m_rot123, xm_ctbl) = m 
  in
  m_rot123.(0)
in

(* ÊªÂÎ€Î¶ÊÌÌÊýÄøŒ°€Î x*z¹à€Î·ž¿ô 2Œ¡¶ÊÌÌ€È±ß¿í€Ç¡¢²óÅŸ€¬€¢€ëŸì¹ç€Î€ß *)
let rec o_param_r2 m = 
  let (xm_tex, xm_shape, xm_surface, xm_isrot, 
       xm_abc, xm_xyz, 
       xm_invert, xm_surfparams, xm_color,
       m_rot123, xm_ctbl) = m 
  in
  m_rot123.(1)
in

(* ÊªÂÎ€Î¶ÊÌÌÊýÄøŒ°€Î x*y¹à€Î·ž¿ô 2Œ¡¶ÊÌÌ€È±ß¿í€Ç¡¢²óÅŸ€¬€¢€ëŸì¹ç€Î€ß *)
let rec o_param_r3 m = 
  let (xm_tex, xm_shape, xm_surface, xm_isrot, 
       xm_abc, xm_xyz, 
       xm_invert, xm_surfparams, xm_color,
       m_rot123, xm_ctbl) = m 
  in
  m_rot123.(2)
in

(* ž÷Àþ€ÎÈ¯ŒÍÅÀ€ò€¢€é€«€ž€á·×»»€·€¿Ÿì¹ç€ÎÄê¿ô¥Æ¡Œ¥Ö¥ë *)
(*
   0 -- 2 ÈÖÌÜ€ÎÍ×ÁÇ: ÊªÂÎ€ÎžÇÍ­ºÂÉž·Ï€ËÊ¿¹Ô°ÜÆ°€·€¿ž÷Àþ»ÏÅÀ
   3ÈÖÌÜ€ÎÍ×ÁÇ: 
   ÄŸÊýÂÎ¢ªÌµžú
   Ê¿ÌÌ¢ª abc¥Ù¥¯¥È¥ë€È€ÎÆâÀÑ
   ÆóŒ¡¶ÊÌÌ¡¢±ß¿í¢ªÆóŒ¡ÊýÄøŒ°€ÎÄê¿ô¹à
 *)
let rec o_param_ctbl m = 
  let (xm_tex, xm_shape, xm_surface, xm_isrot, 
       xm_abc, xm_xyz, 
       xm_invert, xm_surfparams, xm_color,
       xm_rot123, m_ctbl) = m 
  in
  m_ctbl
in

(******************************************************************************
   Pixel¥Ç¡Œ¥¿€Î¥á¥ó¥Ð¥¢¥¯¥»¥¹ŽØ¿ô·² 
 *****************************************************************************)

(* ÄŸÀÜž÷ÄÉÀ×€ÇÆÀ€é€ì€¿¥Ô¥¯¥»¥ë€ÎRGBÃÍ *)
let rec p_rgb pixel = 
  let (m_rgb, xm_isect_ps, xm_sids, xm_cdif, xm_engy,
       xm_r20p, xm_gid, xm_nvectors ) = pixel in
  m_rgb
in

(* Èô€Ð€·€¿ž÷€¬ÊªÂÎ€ÈŸ×ÆÍ€·€¿ÅÀ€ÎÇÛÎó *)
let rec p_intersection_points pixel = 
  let (xm_rgb, m_isect_ps, xm_sids, xm_cdif, xm_engy,
       xm_r20p, xm_gid, xm_nvectors ) = pixel in
  m_isect_ps
in

(* Èô€Ð€·€¿ž÷€¬Ÿ×ÆÍ€·€¿ÊªÂÎÌÌÈÖ¹æ€ÎÇÛÎó *)
(* ÊªÂÎÌÌÈÖ¹æ€Ï ¥ª¥Ö¥ž¥§¥¯¥ÈÈÖ¹æ * 4 + (solver€ÎÊÖ€êÃÍ) *)
let rec p_surface_ids pixel = 
  let (xm_rgb, xm_isect_ps, m_sids, xm_cdif, xm_engy,
       xm_r20p, xm_gid, xm_nvectors ) = pixel in
  m_sids
in

(* ŽÖÀÜŒõž÷€ò·×»»€¹€ë€«ÈÝ€«€Î¥Õ¥é¥° *)
let rec p_calc_diffuse pixel = 
  let (xm_rgb, xm_isect_ps, xm_sids, m_cdif, xm_engy,
       xm_r20p, xm_gid, xm_nvectors ) = pixel in
  m_cdif
in

(* Ÿ×ÆÍÅÀ€ÎŽÖÀÜŒõž÷¥š¥Í¥ë¥®¡Œ€¬¥Ô¥¯¥»¥ëµ±ÅÙ€ËÍ¿€š€ëŽóÍ¿€ÎÂç€­€µ *)
let rec p_energy pixel =
  let (xm_rgb, xm_isect_ps, xm_sids, xm_cdif, m_engy,
       xm_r20p, xm_gid, xm_nvectors ) = pixel in
  m_engy
in

(* Ÿ×ÆÍÅÀ€ÎŽÖÀÜŒõž÷¥š¥Í¥ë¥®¡Œ€òž÷ÀþËÜ¿ô€ò1/5€ËŽÖ°ú€­€·€Æ·×»»€·€¿ÃÍ *)
let rec p_received_ray_20percent pixel =
  let (xm_rgb, xm_isect_ps, xm_sids, xm_cdif, xm_engy,
       m_r20p, xm_gid, xm_nvectors ) = pixel in
  m_r20p
in

(* €³€Î¥Ô¥¯¥»¥ë€Î¥°¥ë¡Œ¥× ID *)
(* 
   ¥¹¥¯¥ê¡Œ¥óºÂÉž (x,y)€ÎÅÀ€Î¥°¥ë¡Œ¥×ID€ò (x+2*y) mod 5 €ÈÄê€á€ë
   ·ë²Ì¡¢²Œ¿Þ€Î€è€Š€ÊÊ¬€±Êý€Ë€Ê€ê¡¢³ÆÅÀ€ÏŸå²Œºž±Š4ÅÀ€ÈÊÌ€Ê¥°¥ë¡Œ¥×€Ë€Ê€ë
   0 1 2 3 4 0 1 2 3 4 
   2 3 4 0 1 2 3 4 0 1
   4 0 1 2 3 4 0 1 2 3
   1 2 3 4 0 1 2 3 4 0
*)

let rec p_group_id pixel =
  let (xm_rgb, xm_isect_ps, xm_sids, xm_cdif, xm_engy,
       xm_r20p, m_gid, xm_nvectors ) = pixel in
  m_gid.(0)
in
   
(* ¥°¥ë¡Œ¥×ID€ò¥»¥Ã¥È€¹€ë¥¢¥¯¥»¥¹ŽØ¿ô *)
let rec p_set_group_id pixel id =
  let (xm_rgb, xm_isect_ps, xm_sids, xm_cdif, xm_engy,
       xm_r20p, m_gid, xm_nvectors ) = pixel in
  m_gid.(0) <- id
in

(* ³ÆŸ×ÆÍÅÀ€Ë€ª€±€ëË¡Àþ¥Ù¥¯¥È¥ë *)
let rec p_nvectors pixel =
  let (xm_rgb, xm_isect_ps, xm_sids, xm_cdif, xm_engy,
       xm_r20p, xm_gid, m_nvectors ) = pixel in
  m_nvectors
in

(******************************************************************************
   Á°œèÍýºÑ€ßÊýžþ¥Ù¥¯¥È¥ë€Î¥á¥ó¥Ð¥¢¥¯¥»¥¹ŽØ¿ô
 *****************************************************************************)

(* ¥Ù¥¯¥È¥ë *)
let rec d_vec d =
  let (m_vec, xm_const) = d in
  m_vec
in

(* ³Æ¥ª¥Ö¥ž¥§¥¯¥È€ËÂÐ€·€Æºî€Ã€¿ solver ¹âÂ®²œÍÑÄê¿ô¥Æ¡Œ¥Ö¥ë *)
let rec d_const d =
  let (dm_vec, m_const) = d in
  m_const
in
   
(******************************************************************************
   Ê¿ÌÌ¶ÀÌÌÂÎ€ÎÈ¿ŒÍŸðÊó
 *****************************************************************************)

(* ÌÌÈÖ¹æ ¥ª¥Ö¥ž¥§¥¯¥ÈÈÖ¹æ*4 + (solver€ÎÊÖ€êÃÍ) *)
let rec r_surface_id r =
  let (m_sid, xm_dvec, xm_br) = r in
  m_sid
in

(* ž÷ž»ž÷€ÎÈ¿ŒÍÊýžþ¥Ù¥¯¥È¥ë(ž÷€ÈµÕžþ€­) *)
let rec r_dvec r =
  let (xm_sid, m_dvec, xm_br) = r in
  m_dvec
in
   
(* ÊªÂÎ€ÎÈ¿ŒÍÎš *)
let rec r_bright r =
  let (xm_sid, xm_dvec, m_br) = r in
  m_br
in

(******************************************************************************
   ¥Ç¡Œ¥¿ÆÉ€ß¹þ€ß€ÎŽØ¿ô·² 
 *****************************************************************************)

(* ¥é¥ž¥¢¥ó *)
let rec rad x = 
  x *. 0.017453293
in

(**** ŽÄ¶­¥Ç¡Œ¥¿€ÎÆÉ€ß¹þ€ß ****)
let rec read_screen_settings _ =
  
  (* ¥¹¥¯¥ê¡Œ¥óÃæ¿Ž€ÎºÂÉž *)
  screen.(0) <- read_float ();
  screen.(1) <- read_float ();
  screen.(2) <- read_float ();
  (* ²óÅŸ³Ñ *)
  let v1 = rad (read_float ()) in
  let cos_v1 = cos v1 in
  let sin_v1 = sin v1 in
  let v2 = rad (read_float ()) in
  let cos_v2 = cos v2 in
  let sin_v2 = sin v2 in
  (* ¥¹¥¯¥ê¡Œ¥óÌÌ€Î±ü¹Ô€­Êýžþ€Î¥Ù¥¯¥È¥ë Ãí»ëÅÀ€«€é€Îµ÷Î¥200€ò€«€±€ë *)
  screenz_dir.(0) <- cos_v1 *. sin_v2 *. 200.0;
  screenz_dir.(1) <- sin_v1 *. -200.0;
  screenz_dir.(2) <- cos_v1 *. cos_v2 *. 200.0;
  (* ¥¹¥¯¥ê¡Œ¥óÌÌXÊýžþ€Î¥Ù¥¯¥È¥ë *)
  screenx_dir.(0) <- cos_v2;
  screenx_dir.(1) <- 0.0;
  screenx_dir.(2) <- fneg sin_v2;
  (* ¥¹¥¯¥ê¡Œ¥óÌÌYÊýžþ€Î¥Ù¥¯¥È¥ë *)
  screeny_dir.(0) <- fneg sin_v1 *. sin_v2;
  screeny_dir.(1) <- fneg cos_v1;
  screeny_dir.(2) <- fneg sin_v1 *. cos_v2;
  (* »ëÅÀ°ÌÃÖ¥Ù¥¯¥È¥ë(ÀäÂÐºÂÉž) *)
  viewpoint.(0) <- screen.(0) -. screenz_dir.(0);
  viewpoint.(1) <- screen.(1) -. screenz_dir.(1);
  viewpoint.(2) <- screen.(2) -. screenz_dir.(2)

in

(* ž÷ž»ŸðÊó€ÎÆÉ€ß¹þ€ß *)
let rec read_light _ =
   
  let nl = read_int () in

  (* ž÷ÀþŽØ·ž *)
  let l1 = rad (read_float ()) in
  let sl1 = sin l1 in
  light.(1) <- fneg sl1;
  let l2 = rad (read_float ()) in
  let cl1 = cos l1 in
  let sl2 = sin l2 in
  light.(0) <- cl1 *. sl2;
  let cl2 = cos l2 in
  light.(2) <- cl1 *. cl2;
  beam.(0) <- read_float ()

in

(* žµ€Î2Œ¡·ÁŒ°¹ÔÎó A €ËÎŸÂŠ€«€é²óÅŸ¹ÔÎó R €ò€«€±€¿¹ÔÎó R^t * A * R €òºî€ë *)
(* R €Ï x,y,zŒŽ€ËŽØ€¹€ë²óÅŸ¹ÔÎó€ÎÀÑ R(z)R(y)R(x) *)
(* ¥¹¥¯¥ê¡Œ¥óºÂÉž€Î€¿€á¡¢yŒŽ²óÅŸ€Î€ß³ÑÅÙ€ÎÉä¹æ€¬µÕ *)

let rec rotate_quadratic_matrix abc rot =
  (* ²óÅŸ¹ÔÎó€ÎÀÑ R(z)R(y)R(x) €ò·×»»€¹€ë *)
  let cos_x = cos rot.(0) in
  let sin_x = sin rot.(0) in
  let cos_y = cos rot.(1) in
  let sin_y = sin rot.(1) in
  let cos_z = cos rot.(2) in
  let sin_z = sin rot.(2) in

  let m00 = cos_y *. cos_z in
  let m01 = sin_x *. sin_y *. cos_z -. cos_x *. sin_z in
  let m02 = cos_x *. sin_y *. cos_z +. sin_x *. sin_z in

  let m10 = cos_y *. sin_z in
  let m11 = sin_x *. sin_y *. sin_z +. cos_x *. cos_z in
  let m12 = cos_x *. sin_y *. sin_z -. sin_x *. cos_z in

  let m20 = fneg sin_y in
  let m21 = sin_x *. cos_y in
  let m22 = cos_x *. cos_y in

  (* a, b, c€Îžµ€ÎÃÍ€ò¥Ð¥Ã¥¯¥¢¥Ã¥× *)
  let ao = abc.(0) in
  let bo = abc.(1) in
  let co = abc.(2) in
	 
  (* R^t * A * R €ò·×»» *)
	 
  (* X^2, Y^2, Z^2À®Ê¬ *)
  abc.(0) <- ao *. fsqr m00 +. bo *. fsqr m10 +. co *. fsqr m20;
  abc.(1) <- ao *. fsqr m01 +. bo *. fsqr m11 +. co *. fsqr m21;
  abc.(2) <- ao *. fsqr m02 +. bo *. fsqr m12 +. co *. fsqr m22;

  (* ²óÅŸ€Ë€è€Ã€ÆÀž€ž€¿ XY, YZ, ZXÀ®Ê¬ *)
  rot.(0) <- 2.0 *. (ao *. m01 *. m02 +. bo *. m11 *. m12 +. co *. m21 *. m22);
  rot.(1) <- 2.0 *. (ao *. m00 *. m02 +. bo *. m10 *. m12 +. co *. m20 *. m22);
  rot.(2) <- 2.0 *. (ao *. m00 *. m01 +. bo *. m10 *. m11 +. co *. m20 *. m21)

in

(**** ¥ª¥Ö¥ž¥§¥¯¥È1€Ä€Î¥Ç¡Œ¥¿€ÎÆÉ€ß¹þ€ß ****)
let rec read_nth_object n =

  let texture = read_int () in                      
  if texture <> -1 then
    ( 
      let form = read_int () in                     
      let refltype = read_int () in
      let isrot_p = read_int () in

      let abc = Array.create 3 0.0 in
      abc.(0) <- read_float ();
      abc.(1) <- read_float (); (* 5 *)
      abc.(2) <- read_float ();

      let xyz = Array.create 3 0.0 in
      xyz.(0) <- read_float ();
      xyz.(1) <- read_float ();
      xyz.(2) <- read_float ();

      let m_invert = fisneg (read_float ()) in (* 10 *)

      let reflparam = Array.create 2 0.0 in      
      reflparam.(0) <- read_float (); (* diffuse *)
      reflparam.(1) <- read_float (); (* hilight *)
       
      let color = Array.create 3 0.0 in
      color.(0) <- read_float ();
      color.(1) <- read_float ();
      color.(2) <- read_float (); (* 15 *)
     
      let rotation = Array.create 3 0.0 in
      if isrot_p <> 0 then
	(
	 rotation.(0) <- rad (read_float ());
	 rotation.(1) <- rad (read_float ());
	 rotation.(2) <- rad (read_float ())
	) 
      else ();

      (* ¥Ñ¥é¥á¡Œ¥¿€ÎÀµµ¬²œ *)

      (* Ãí: ²Œµ­Àµµ¬²œ (form = 2) »²ŸÈ *)
      let m_invert2 = if form = 2 then true else m_invert in
      let ctbl = Array.create 4 0.0 in
      (* €³€³€«€é€¢€È€Ï abc €È rotation €·€«Áàºî€·€Ê€€¡£*)
      let obj = 
	(texture, form, refltype, isrot_p,
	 abc, xyz, (* x-z *)
	 m_invert2,
	 reflparam, (* reflection paramater *)
	 color, (* color *)
	 rotation, (* rotation *)
         ctbl (* constant table *)
	) in
      objects.(n) <- obj;

      if form = 3 then
	(
	  (* 2Œ¡¶ÊÌÌ: X,Y,Z ¥µ¥€¥º€«€é2Œ¡·ÁŒ°¹ÔÎó€ÎÂÐ³ÑÀ®Ê¬€Ø *)
	 let a = abc.(0) in
	 abc.(0) <- if fiszero a then 0.0 else sgn a /. fsqr a; (* X^2 À®Ê¬ *)
	 let b = abc.(1) in
	 abc.(1) <- if fiszero b then 0.0 else sgn b /. fsqr b; (* Y^2 À®Ê¬ *)
	 let c = abc.(2) in
	 abc.(2) <- if fiszero c then 0.0 else sgn c /. fsqr c  (* Z^2 À®Ê¬ *)
	)
      else if form = 2 then
	(* Ê¿ÌÌ: Ë¡Àþ¥Ù¥¯¥È¥ë€òÀµµ¬²œ, ¶ËÀ­€òÉé€ËÅý°ì *)
	vecunit_sgn abc (not m_invert)
      else ();

      (* 2Œ¡·ÁŒ°¹ÔÎó€Ë²óÅŸÊÑŽ¹€ò»Ü€¹ *)
      if isrot_p <> 0 then
	rotate_quadratic_matrix abc rotation
      else ();
      
      true
     )
  else
    false (* ¥Ç¡Œ¥¿€ÎœªÎ» *)
in

(**** ÊªÂÎ¥Ç¡Œ¥¿ÁŽÂÎ€ÎÆÉ€ß¹þ€ß ****)
let rec read_object n =
  if n < 60 then
    if read_nth_object n then 
      read_object (n + 1) 
    else
      n_objects.(0) <- n
  else () (* failwith "too many objects" *)
in

let rec read_all_object _ =
  read_object 0
in

(**** AND, OR ¥Í¥Ã¥È¥ï¡Œ¥¯€ÎÆÉ€ß¹þ€ß ****)

(* ¥Í¥Ã¥È¥ï¡Œ¥¯1€Ä€òÆÉ€ß¹þ€ß¥Ù¥¯¥È¥ë€Ë€·€ÆÊÖ€¹ *)
let rec read_net_item length =
  let item = read_int () in
  if item = -1 then Array.create (length + 1) (-1)
  else
    let v = read_net_item (length + 1) in
    (v.(length) <- item; v)
in

let rec read_or_network length =
  let net = read_net_item 0 in
  if net.(0) = -1 then 
    Array.create (length + 1) net
  else
    let v = read_or_network (length + 1) in
    (v.(length) <- net; v)
in

let rec read_and_network n =
  let net = read_net_item 0 in
  if net.(0) = -1 then ()
  else (
    and_net.(n) <- net;
    read_and_network (n + 1)
  )
in

let rec read_parameter _ =
  (
   read_screen_settings();
   read_light();
   read_all_object ();
   read_and_network 0;
   or_net.(0) <- read_or_network 0
  )
in

(******************************************************************************
   ÄŸÀþ€È¥ª¥Ö¥ž¥§¥¯¥È€ÎžòÅÀ€òµá€á€ëŽØ¿ô·² 
 *****************************************************************************)

(* solver : 
   ¥ª¥Ö¥ž¥§¥¯¥È (€Î index) €È¡¢¥Ù¥¯¥È¥ë L, P €òŒõ€±€È€ê¡¢
   ÄŸÀþ Lt + P €È¡¢¥ª¥Ö¥ž¥§¥¯¥È€È€ÎžòÅÀ€òµá€á€ë¡£
   žòÅÀ€¬€Ê€€Ÿì¹ç€Ï 0 €ò¡¢žòÅÀ€¬€¢€ëŸì¹ç€Ï€œ€ì°Ê³°€òÊÖ€¹¡£
   €³€ÎÊÖ€êÃÍ€Ï nvector €ÇžòÅÀ€ÎË¡Àþ¥Ù¥¯¥È¥ë€òµá€á€ëºÝ€ËÉ¬Í×¡£
   (ÄŸÊýÂÎ€ÎŸì¹ç)

   žòÅÀ€ÎºÂÉž€Ï t €ÎÃÍ€È€·€Æ solver_dist €Ë³ÊÇŒ€µ€ì€ë¡£
*)

(* ÄŸÊýÂÎ€Î»ØÄê€µ€ì€¿ÌÌ€ËŸ×ÆÍ€¹€ë€«€É€Š€«ÈœÄê€¹€ë *)
(* i0 : ÌÌ€Ë¿âÄŸ€ÊŒŽ€Îindex X:0, Y:1, Z:2         i2,i3€ÏÂŸ€Î2ŒŽ€Îindex *)
let rec solver_rect_surface m dirvec b0 b1 b2 i0 i1 i2  =
  if fiszero dirvec.(i0) then false else
  let abc = o_param_abc m in
  let d = fneg_cond (xor (o_isinvert m) (fisneg dirvec.(i0))) abc.(i0) in
  
  let d2 = (d -. b0) /. dirvec.(i0) in
  if fless (fabs (d2 *. dirvec.(i1) +. b1)) abc.(i1) then
    if fless (fabs (d2 *. dirvec.(i2) +. b2)) abc.(i2) then
      (solver_dist.(0) <- d2; true)
    else false
  else false
in


(***** ÄŸÊýÂÎ¥ª¥Ö¥ž¥§¥¯¥È€ÎŸì¹ç ****)
let rec solver_rect m dirvec b0 b1 b2 =
  if      solver_rect_surface m dirvec b0 b1 b2 0 1 2 then 1   (* YZ Ê¿ÌÌ *)
  else if solver_rect_surface m dirvec b1 b2 b0 1 2 0 then 2   (* ZX Ê¿ÌÌ *)
  else if solver_rect_surface m dirvec b2 b0 b1 2 0 1 then 3   (* XY Ê¿ÌÌ *)
  else                                                     0
in


(* Ê¿ÌÌ¥ª¥Ö¥ž¥§¥¯¥È€ÎŸì¹ç *)
let rec solver_surface m dirvec b0 b1 b2 =
  (* ÅÀ€ÈÊ¿ÌÌ€ÎÉä¹æ€Ä€­µ÷Î¥ *)
  (* Ê¿ÌÌ€Ï¶ËÀ­€¬Éé€ËÅý°ì€µ€ì€Æ€€€ë *)
  let abc = o_param_abc m in
  let d = veciprod dirvec abc in
  if fispos d then (
    solver_dist.(0) <- fneg (veciprod2 abc b0 b1 b2) /. d;
    1
   ) else 0
in


(* 3ÊÑ¿ô2Œ¡·ÁŒ° v^t A v €ò·×»» *)
(* ²óÅŸ€¬Ìµ€€Ÿì¹ç€ÏÂÐ³ÑÉôÊ¬€Î€ß·×»»€¹€ì€ÐÎÉ€€ *)
let rec quadratic m v0 v1 v2 =
  let diag_part = 
    fsqr v0 *. o_param_a m +. fsqr v1 *. o_param_b m +. fsqr v2 *. o_param_c m
  in
  if o_isrot m = 0 then 
    diag_part
  else
    diag_part
      +. v1 *. v2 *. o_param_r1 m
      +. v2 *. v0 *. o_param_r2 m
      +. v0 *. v1 *. o_param_r3 m
in

(* 3ÊÑ¿ôÁÐ1Œ¡·ÁŒ° v^t A w €ò·×»» *)
(* ²óÅŸ€¬Ìµ€€Ÿì¹ç€Ï A €ÎÂÐ³ÑÉôÊ¬€Î€ß·×»»€¹€ì€ÐÎÉ€€ *)
let rec bilinear m v0 v1 v2 w0 w1 w2 =
  let diag_part = 
    v0 *. w0 *. o_param_a m 
      +. v1 *. w1 *. o_param_b m
      +. v2 *. w2 *. o_param_c m
  in
  if o_isrot m = 0 then
    diag_part
  else
    diag_part +. fhalf 
      ((v2 *. w1 +. v1 *. w2) *. o_param_r1 m
	 +. (v0 *. w2 +. v2 *. w0) *. o_param_r2 m
	 +. (v0 *. w1 +. v1 *. w0) *. o_param_r3 m)
in


(* 2Œ¡¶ÊÌÌ€Þ€¿€Ï±ß¿í€ÎŸì¹ç *)
(* 2Œ¡·ÁŒ°€ÇÉœžœ€µ€ì€¿¶ÊÌÌ x^t A x - (0 €« 1) = 0 €È ÄŸÀþ base + dirvec*t €Î
   žòÅÀ€òµá€á€ë¡£¶ÊÀþ€ÎÊýÄøŒ°€Ë x = base + dirvec*t €òÂåÆþ€·€Æt€òµá€á€ë¡£
   €Ä€Þ€ê (base + dirvec*t)^t A (base + dirvec*t) - (0 €« 1) = 0¡¢
   Åž³«€¹€ë€È (dirvec^t A dirvec)*t^2 + 2*(dirvec^t A base)*t  + 
   (base^t A base) - (0€«1) = 0 ¡¢€è€Ã€Æt€ËŽØ€¹€ë2Œ¡ÊýÄøŒ°€ò²ò€±€ÐÎÉ€€¡£*)

let rec solver_second m dirvec b0 b1 b2 =

  (* ²ò€ÎžøŒ° (-b' ¡Þ sqrt(b'^2 - a*c)) / a  €ò»ÈÍÑ(b' = b/2) *)
  (* a = dirvec^t A dirvec *)
  let aa = quadratic m dirvec.(0) dirvec.(1) dirvec.(2) in

  if fiszero aa then 
    0 (* Àµ³Î€Ë€Ï€³€ÎŸì¹ç€â1Œ¡ÊýÄøŒ°€Î²ò€¬€¢€ë€¬¡¢Ìµ»ë€·€Æ€âÄÌŸï€ÏÂçŸæÉ× *)
  else (
    
    (* b' = b/2 = dirvec^t A base   *)
    let bb = bilinear m dirvec.(0) dirvec.(1) dirvec.(2) b0 b1 b2 in
    (* c = base^t A base  - (0€«1)  *)
    let cc0 = quadratic m b0 b1 b2 in
    let cc = if o_form m = 3 then cc0 -. 1.0 else cc0 in
    (* ÈœÊÌŒ° *)
    let d = fsqr bb -. aa *. cc in 

    if fispos d then (
      let sd = sqrt d in
      let t1 = if o_isinvert m then sd else fneg sd in
      (solver_dist.(0) <- (t1 -. bb) /.  aa; 1)
     ) 
    else 
      0
   )
in

(**** solver €Î¥á¥€¥ó¥ë¡Œ¥Á¥ó ****)
let rec solver index dirvec org =
  let m = objects.(index) in
  (* ÄŸÀþ€Î»ÏÅÀ€òÊªÂÎ€ÎŽðœà°ÌÃÖ€Ë¹ç€ï€»€ÆÊ¿¹Ô°ÜÆ° *)
  let b0 =  org.(0) -. o_param_x m in
  let b1 =  org.(1) -. o_param_y m in
  let b2 =  org.(2) -. o_param_z m in
  let m_shape = o_form m in
  (* ÊªÂÎ€ÎŒïÎà€Ë±þ€ž€¿ÊäœõŽØ¿ô€òžÆ€Ö *)
  if m_shape = 1 then       solver_rect m dirvec b0 b1 b2    (* ÄŸÊýÂÎ *)
  else if m_shape = 2 then  solver_surface m dirvec b0 b1 b2 (* Ê¿ÌÌ *)
  else                      solver_second m dirvec b0 b1 b2  (* 2Œ¡¶ÊÌÌ/±ß¿í *)
in

(******************************************************************************
   solver€Î¥Æ¡Œ¥Ö¥ë»ÈÍÑ¹âÂ®ÈÇ
 *****************************************************************************)
(*
   ÄÌŸïÈÇsolver €ÈÆ±ÍÍ¡¢ÄŸÀþ start + t * dirvec €ÈÊªÂÎ€ÎžòÅÀ€ò t €ÎÃÍ€È€·€ÆÊÖ€¹
   t €ÎÃÍ€Ï solver_dist€Ë³ÊÇŒ
   
   solver_fast €Ï¡¢ÄŸÀþ€ÎÊýžþ¥Ù¥¯¥È¥ë dirvec €Ë€Ä€€€Æºî€Ã€¿¥Æ¡Œ¥Ö¥ë€ò»ÈÍÑ
   ÆâÉôÅª€Ë solver_rect_fast, solver_surface_fast, solver_second_fast€òžÆ€Ö
   
   solver_fast2 €Ï¡¢dirvec€ÈÄŸÀþ€Î»ÏÅÀ start €œ€ì€Ÿ€ì€Ëºî€Ã€¿¥Æ¡Œ¥Ö¥ë€ò»ÈÍÑ
   ÄŸÊýÂÎ€Ë€Ä€€€Æ€Ïstart€Î¥Æ¡Œ¥Ö¥ë€Ë€è€ë¹âÂ®²œ€Ï€Ç€­€Ê€€€Î€Ç¡¢solver_fast€È
   Æ±€ž€¯ solver_rect_fast€òÆâÉôÅª€ËžÆ€Ö¡£€œ€ì°Ê³°€ÎÊªÂÎ€Ë€Ä€€€Æ€Ï
   solver_surface_fast2€Þ€¿€Ïsolver_second_fast2€òÆâÉôÅª€ËžÆ€Ö

   ÊÑ¿ôdconst€ÏÊýžþ¥Ù¥¯¥È¥ë¡¢sconst€Ï»ÏÅÀ€ËŽØ€¹€ë¥Æ¡Œ¥Ö¥ë
*)

(***** solver_rect€Îdirvec¥Æ¡Œ¥Ö¥ë»ÈÍÑ¹âÂ®ÈÇ ******)
let rec solver_rect_fast m v dconst b0 b1 b2 =
  let d0 = (dconst.(0) -. b0) *. dconst.(1) in
  if  (* YZÊ¿ÌÌ€È€ÎŸ×ÆÍÈœÄê *)
    if fless (fabs (d0 *. v.(1) +. b1)) (o_param_b m) then
      if fless (fabs (d0 *. v.(2) +. b2)) (o_param_c m) then
	not (fiszero dconst.(1))
      else false
    else false
  then
    (solver_dist.(0) <- d0; 1)
  else let d1 = (dconst.(2) -. b1) *. dconst.(3) in 
  if  (* ZXÊ¿ÌÌ€È€ÎŸ×ÆÍÈœÄê *)
    if fless (fabs (d1 *. v.(0) +. b0)) (o_param_a m) then
      if fless (fabs (d1 *. v.(2) +. b2)) (o_param_c m) then
	not (fiszero dconst.(3))
      else false
    else false
  then
    (solver_dist.(0) <- d1; 2)
  else let d2 = (dconst.(4) -. b2) *. dconst.(5) in 
  if  (* XYÊ¿ÌÌ€È€ÎŸ×ÆÍÈœÄê *)
    if fless (fabs (d2 *. v.(0) +. b0)) (o_param_a m) then
      if fless (fabs (d2 *. v.(1) +. b1)) (o_param_b m) then
	not (fiszero dconst.(5))
      else false
    else false
  then
    (solver_dist.(0) <- d2; 3)
  else
    0
in

(**** solver_surface€Îdirvec¥Æ¡Œ¥Ö¥ë»ÈÍÑ¹âÂ®ÈÇ ******)
let rec solver_surface_fast m dconst b0 b1 b2 =
  if fisneg dconst.(0) then (
    solver_dist.(0) <- 
      dconst.(1) *. b0 +. dconst.(2) *. b1 +. dconst.(3) *. b2;
    1 
   ) else 0
in

(**** solver_second €Îdirvec¥Æ¡Œ¥Ö¥ë»ÈÍÑ¹âÂ®ÈÇ ******)
let rec solver_second_fast m dconst b0 b1 b2 =
  
  let aa = dconst.(0) in
  if fiszero aa then
    0
  else 
    let neg_bb = dconst.(1) *. b0 +. dconst.(2) *. b1 +. dconst.(3) *. b2 in
    let cc0 = quadratic m b0 b1 b2 in
    let cc = if o_form m = 3 then cc0 -. 1.0 else cc0 in
    let d = (fsqr neg_bb) -. aa *. cc in
    if fispos d then (
      if o_isinvert m then
	solver_dist.(0) <- (neg_bb +. sqrt d) *. dconst.(4)
      else
	solver_dist.(0) <- (neg_bb -. sqrt d) *. dconst.(4);
      1)
    else 0
in

(**** solver €Îdirvec¥Æ¡Œ¥Ö¥ë»ÈÍÑ¹âÂ®ÈÇ *******)
let rec solver_fast index dirvec org =
  let m = objects.(index) in
  let b0 = org.(0) -. o_param_x m in
  let b1 = org.(1) -. o_param_y m in 
  let b2 = org.(2) -. o_param_z m in
  let dconsts = d_const dirvec in
  let dconst = dconsts.(index) in
  let m_shape = o_form m in
  if m_shape = 1 then       
    solver_rect_fast m (d_vec dirvec) dconst b0 b1 b2
  else if m_shape = 2 then  
    solver_surface_fast m dconst b0 b1 b2
  else                      
    solver_second_fast m dconst b0 b1 b2
in




(* solver_surface€Îdirvec+start¥Æ¡Œ¥Ö¥ë»ÈÍÑ¹âÂ®ÈÇ *)
let rec solver_surface_fast2 m dconst sconst b0 b1 b2 =
  if fisneg dconst.(0) then (
    solver_dist.(0) <- dconst.(0) *. sconst.(3);
    1 
   ) else 0
in

(* solver_second€Îdirvec+start¥Æ¡Œ¥Ö¥ë»ÈÍÑ¹âÂ®ÈÇ *)
let rec solver_second_fast2 m dconst sconst b0 b1 b2 =
  
  let aa = dconst.(0) in
  if fiszero aa then
    0
  else 
    let neg_bb = dconst.(1) *. b0 +. dconst.(2) *. b1 +. dconst.(3) *. b2 in
    let cc = sconst.(3) in
    let d = (fsqr neg_bb) -. aa *. cc in
    if fispos d then (
      if o_isinvert m then
	solver_dist.(0) <- (neg_bb +. sqrt d) *. dconst.(4)
      else
	solver_dist.(0) <- (neg_bb -. sqrt d) *. dconst.(4);
      1)
    else 0
in

(* solver€Î¡¢dirvec+start¥Æ¡Œ¥Ö¥ë»ÈÍÑ¹âÂ®ÈÇ *)
let rec solver_fast2 index dirvec =
  let m = objects.(index) in
  let sconst = o_param_ctbl m in
  let b0 = sconst.(0) in
  let b1 = sconst.(1) in
  let b2 = sconst.(2) in
  let dconsts = d_const dirvec in
  let dconst = dconsts.(index) in
  let m_shape = o_form m in
  if m_shape = 1 then       
    solver_rect_fast m (d_vec dirvec) dconst b0 b1 b2
  else if m_shape = 2 then  
    solver_surface_fast2 m dconst sconst b0 b1 b2
  else                      
    solver_second_fast2 m dconst sconst b0 b1 b2
in

(******************************************************************************
   Êýžþ¥Ù¥¯¥È¥ë€ÎÄê¿ô¥Æ¡Œ¥Ö¥ë€ò·×»»€¹€ëŽØ¿ô·²
 *****************************************************************************)

(* ÄŸÊýÂÎ¥ª¥Ö¥ž¥§¥¯¥È€ËÂÐ€¹€ëÁ°œèÍý *)
let rec setup_rect_table vec m = 
  let const = Array.create 6 0.0 in

  if fiszero vec.(0) then (* YZÊ¿ÌÌ *)
    const.(1) <- 0.0
  else (
    (* ÌÌ€Î X ºÂÉž *)
    const.(0) <- fneg_cond (xor (o_isinvert m) (fisneg vec.(0))) (o_param_a m);
    (* Êýžþ¥Ù¥¯¥È¥ë€ò²¿ÇÜ€¹€ì€ÐXÊýžþ€Ë1¿Ê€à€« *)
    const.(1) <- 1.0 /. vec.(0)
  );
  if fiszero vec.(1) then (* ZXÊ¿ÌÌ : YZÊ¿ÌÌ€ÈÆ±ÍÍ*)
    const.(3) <- 0.0
  else (
    const.(2) <- fneg_cond (xor (o_isinvert m) (fisneg vec.(1))) (o_param_b m);
    const.(3) <- 1.0 /. vec.(1)
  );
  if fiszero vec.(2) then (* XYÊ¿ÌÌ : YZÊ¿ÌÌ€ÈÆ±ÍÍ*)
    const.(5) <- 0.0
  else (
    const.(4) <- fneg_cond (xor (o_isinvert m) (fisneg vec.(2))) (o_param_c m);
    const.(5) <- 1.0 /. vec.(2)
  );
  const
in

(* Ê¿ÌÌ¥ª¥Ö¥ž¥§¥¯¥È€ËÂÐ€¹€ëÁ°œèÍý *)
let rec setup_surface_table vec m = 
  let const = Array.create 4 0.0 in
  let d = 
    vec.(0) *. o_param_a m +. vec.(1) *. o_param_b m +. vec.(2) *. o_param_c m
  in
  if fispos d then (
    (* Êýžþ¥Ù¥¯¥È¥ë€ò²¿ÇÜ€¹€ì€ÐÊ¿ÌÌ€Î¿âÄŸÊýžþ€Ë 1 ¿Ê€à€« *)
    const.(0) <- -1.0 /. d;
    (* €¢€ëÅÀ€ÎÊ¿ÌÌ€«€é€Îµ÷Î¥€¬Êýžþ¥Ù¥¯¥È¥ë²¿žÄÊ¬€«€òÆ³€¯3Œ¡°ì·ÁŒ°€Î·ž¿ô *)
    const.(1) <- fneg (o_param_a m /. d);
    const.(2) <- fneg (o_param_b m /. d);
    const.(3) <- fneg (o_param_c m /. d)
   ) else
    const.(0) <- 0.0;
  const
 
in

(* 2Œ¡¶ÊÌÌ€ËÂÐ€¹€ëÁ°œèÍý *)
let rec setup_second_table v m = 
  let const = Array.create 5 0.0 in
  
  let aa = quadratic m v.(0) v.(1) v.(2) in
  let c1 = fneg (v.(0) *. o_param_a m) in
  let c2 = fneg (v.(1) *. o_param_b m) in
  let c3 = fneg (v.(2) *. o_param_c m) in

  const.(0) <- aa;  (* 2Œ¡ÊýÄøŒ°€Î a ·ž¿ô *)

  (* b' = dirvec^t A start €À€¬¡¢(dirvec^t A)€ÎÉôÊ¬€ò·×»»€·const.(1:3)€Ë³ÊÇŒ¡£
     b' €òµá€á€ë€Ë€Ï€³€Î¥Ù¥¯¥È¥ë€Èstart€ÎÆâÀÑ€òŒè€ì€ÐÎÉ€€¡£Éä¹æ€ÏµÕ€Ë€¹€ë *)
  if o_isrot m <> 0 then (
    const.(1) <- c1 -. fhalf (v.(2) *. o_param_r2 m +. v.(1) *. o_param_r3 m);
    const.(2) <- c2 -. fhalf (v.(2) *. o_param_r1 m +. v.(0) *. o_param_r3 m);
    const.(3) <- c3 -. fhalf (v.(1) *. o_param_r1 m +. v.(0) *. o_param_r2 m)
   ) else (
    const.(1) <- c1;
    const.(2) <- c2;
    const.(3) <- c3
   );
  if not (fiszero aa) then
    const.(4) <- 1.0 /. aa (* a·ž¿ô€ÎµÕ¿ô€òµá€á¡¢²ò€ÎžøŒ°€Ç€Î³ä€ê»»€òŸÃµî *)
  else ();
  const

in

(* ³Æ¥ª¥Ö¥ž¥§¥¯¥È€Ë€Ä€€€ÆÊäœõŽØ¿ô€òžÆ€ó€Ç¥Æ¡Œ¥Ö¥ë€òºî€ë *)
let rec iter_setup_dirvec_constants dirvec index =
  if index >= 0 then (
    let m = objects.(index) in
    let dconst = (d_const dirvec) in
    let v = d_vec dirvec in
    let m_shape = o_form m in
    if m_shape = 1 then  (* rect *)
      dconst.(index) <- setup_rect_table v m
    else if m_shape = 2 then  (* surface *)
      dconst.(index) <- setup_surface_table v m
    else                      (* second *)
      dconst.(index) <- setup_second_table v m;
    
    iter_setup_dirvec_constants dirvec (index - 1)
  ) else ()
in

let rec setup_dirvec_constants dirvec =
  iter_setup_dirvec_constants dirvec (n_objects.(0) - 1)
in

(******************************************************************************
   ÄŸÀþ€Î»ÏÅÀ€ËŽØ€¹€ë¥Æ¡Œ¥Ö¥ë€ò³Æ¥ª¥Ö¥ž¥§¥¯¥È€ËÂÐ€·€Æ·×»»€¹€ëŽØ¿ô·²
 *****************************************************************************)

let rec setup_startp_constants p index =
  if index >= 0 then (
    let obj = objects.(index) in
    let sconst = o_param_ctbl obj in
    let m_shape = o_form obj in
    sconst.(0) <- p.(0) -. o_param_x obj;
    sconst.(1) <- p.(1) -. o_param_y obj;
    sconst.(2) <- p.(2) -. o_param_z obj;
    if m_shape = 2 then (* surface *)
      sconst.(3) <- 
	veciprod2 (o_param_abc obj) sconst.(0) sconst.(1) sconst.(2)
    else if m_shape > 2 then (* second *)
      let cc0 = quadratic obj sconst.(0) sconst.(1) sconst.(2) in
      sconst.(3) <- if m_shape = 3 then cc0 -. 1.0 else cc0
    else ();
    setup_startp_constants p (index - 1)
   ) else ()
in

let rec setup_startp p =
  veccpy startp_fast p;
  setup_startp_constants p (n_objects.(0) - 1)
in

(******************************************************************************
   Í¿€š€é€ì€¿ÅÀ€¬¥ª¥Ö¥ž¥§¥¯¥È€ËŽÞ€Þ€ì€ë€«€É€Š€«€òÈœÄê€¹€ëŽØ¿ô·² 
 *****************************************************************************)

(**** ÅÀ q €¬¥ª¥Ö¥ž¥§¥¯¥È m €Î³°Éô€«€É€Š€«€òÈœÄê€¹€ë ****)

(* ÄŸÊýÂÎ *)
let rec is_rect_outside m p0 p1 p2 =
  if 
    if (fless (fabs p0) (o_param_a m)) then
      if (fless (fabs p1) (o_param_b m)) then
	fless (fabs p2) (o_param_c m)
      else false
    else false
  then o_isinvert m else not (o_isinvert m)
in

(* Ê¿ÌÌ *)
let rec is_plane_outside m p0 p1 p2 =
  let w = veciprod2 (o_param_abc m) p0 p1 p2 in
  not (xor (o_isinvert m) (fisneg w))
in

(* 2Œ¡¶ÊÌÌ *)
let rec is_second_outside m p0 p1 p2 = 
  let w = quadratic m p0 p1 p2 in
  let w2 = if o_form m = 3 then w -. 1.0 else w in
  not (xor (o_isinvert m) (fisneg w2))
in

(* ÊªÂÎ€ÎÃæ¿ŽºÂÉž€ËÊ¿¹Ô°ÜÆ°€·€¿Ÿå€Ç¡¢Å¬ÀÚ€ÊÊäœõŽØ¿ô€òžÆ€Ö *)
let rec is_outside m q0 q1 q2 =
  let p0 = q0 -. o_param_x m in
  let p1 = q1 -. o_param_y m in
  let p2 = q2 -. o_param_z m in
  let m_shape = o_form m in
  if m_shape = 1 then
    is_rect_outside m p0 p1 p2
  else if m_shape = 2 then
    is_plane_outside m p0 p1 p2
  else 
    is_second_outside m p0 p1 p2
in

(**** ÅÀ q €¬ AND ¥Í¥Ã¥È¥ï¡Œ¥¯ iand €ÎÆâÉô€Ë€¢€ë€«€É€Š€«€òÈœÄê ****)
let rec check_all_inside ofs iand q0 q1 q2 =
  let head = iand.(ofs) in
  if head = -1 then 
    true 
  else (
    if is_outside objects.(head) q0 q1 q2 then 
      false
    else 
      check_all_inside (ofs + 1) iand q0 q1 q2
   )
in

(******************************************************************************
   Ÿ×ÆÍÅÀ€¬ÂŸ€ÎÊªÂÎ€Î±Æ€ËÆþ€Ã€Æ€€€ë€«ÈÝ€«€òÈœÄê€¹€ëŽØ¿ô·² 
 *****************************************************************************)

(* ÅÀ intersection_point €«€é¡¢ž÷Àþ¥Ù¥¯¥È¥ë€ÎÊýžþ€ËÃ©€ê¡¢   *)
(* ÊªÂÎ€Ë€Ö€Ä€«€ë (=±Æ€Ë€Ï€€€Ã€Æ€€€ë) €«ÈÝ€«€òÈœÄê€¹€ë¡£*)

(**** AND ¥Í¥Ã¥È¥ï¡Œ¥¯ iand €Î±ÆÆâ€«€É€Š€«€ÎÈœÄê ****)
let rec shadow_check_and_group iand_ofs and_group =
  if and_group.(iand_ofs) = -1 then
    false
  else
    let obj = and_group.(iand_ofs) in
    let t0 = solver_fast obj light_dirvec intersection_point in
    let t0p = solver_dist.(0) in
    if (if t0 <> 0 then fless t0p (-0.2) else false) then 
      (* Q: žòÅÀ€ÎžõÊä¡£ŒÂºÝ€Ë€¹€Ù€Æ€Î¥ª¥Ö¥ž¥§¥¯¥È€Ë *)
      (* Æþ€Ã€Æ€€€ë€«€É€Š€«€òÄŽ€Ù€ë¡£*)
      let t = t0p +. 0.01 in
      let q0 = light.(0) *. t +. intersection_point.(0) in
      let q1 = light.(1) *. t +. intersection_point.(1) in
      let q2 = light.(2) *. t +. intersection_point.(2) in
      if check_all_inside 0 and_group q0 q1 q2 then
	true 
      else 
	shadow_check_and_group (iand_ofs + 1) and_group 
	  (* Œ¡€Î¥ª¥Ö¥ž¥§¥¯¥È€«€éžõÊäÅÀ€òÃµ€¹ *)
    else
      (* žòÅÀ€¬€Ê€€Ÿì¹ç: ¶ËÀ­€¬Àµ(ÆâÂŠ€¬¿¿)€ÎŸì¹ç¡¢    *)
      (* AND ¥Í¥Ã¥È€Î¶ŠÄÌÉôÊ¬€Ï€œ€ÎÆâÉô€ËŽÞ€Þ€ì€ë€¿€á¡¢*)
      (* žòÅÀ€Ï€Ê€€€³€È€ÏŒ«ÌÀ¡£Ãµº÷€òÂÇ€ÁÀÚ€ë¡£        *)
      if o_isinvert (objects.(obj)) then 
	shadow_check_and_group (iand_ofs + 1) and_group
      else 
	false
in

(**** OR ¥°¥ë¡Œ¥× or_group €Î±Æ€«€É€Š€«€ÎÈœÄê ****)
let rec shadow_check_one_or_group ofs or_group =
  let head = or_group.(ofs) in
  if head = -1 then
    false
  else (
    let and_group = and_net.(head) in
    let shadow_p = shadow_check_and_group 0 and_group in
    if shadow_p then
      true
    else 
      shadow_check_one_or_group (ofs + 1) or_group
   )
in

(**** OR ¥°¥ë¡Œ¥×€ÎÎó€Î€É€ì€«€Î±Æ€ËÆþ€Ã€Æ€€€ë€«€É€Š€«€ÎÈœÄê ****)
let rec shadow_check_one_or_matrix ofs or_matrix =
  let head = or_matrix.(ofs) in
  let range_primitive = head.(0) in
  if range_primitive = -1 then (* OR¹ÔÎó€ÎœªÎ»¥Þ¡Œ¥¯ *)
    false 
  else
    if (* range primitive €¬Ìµ€€€«¡¢€Þ€¿€Ïrange_primitive€Èžò€ï€ë»ö€ò³ÎÇ§ *)
      if range_primitive = 99 then      (* range primitive €¬Ìµ€€ *)
	true
      else              (* range_primitive€¬€¢€ë *)
	let t = solver_fast range_primitive light_dirvec intersection_point in
        (* range primitive €È€Ö€Ä€«€é€Ê€±€ì€Ð *)
        (* or group €È€ÎžòÅÀ€Ï€Ê€€            *)
	if t <> 0 then
          if fless solver_dist.(0) (-0.1) then
            if shadow_check_one_or_group 1 head then
              true
	    else false
	  else false
	else false
    then
      if (shadow_check_one_or_group 1 head) then 
	true (* žòÅÀ€¬€¢€ë€Î€Ç¡¢±Æ€ËÆþ€ë»ö€¬ÈœÌÀ¡£Ãµº÷œªÎ» *)
      else 
	shadow_check_one_or_matrix (ofs + 1) or_matrix (* Œ¡€ÎÍ×ÁÇ€ò»î€¹ *)
    else 
      shadow_check_one_or_matrix (ofs + 1) or_matrix (* Œ¡€ÎÍ×ÁÇ€ò»î€¹ *)
	
in

(******************************************************************************
   ž÷Àþ€ÈÊªÂÎ€Îžòº¹ÈœÄê
 *****************************************************************************)

(**** €¢€ëAND¥Í¥Ã¥È¥ï¡Œ¥¯€¬¡¢¥ì¥€¥È¥ì¡Œ¥¹€ÎÊýžþ€ËÂÐ€·¡¢****)
(**** žòÅÀ€¬€¢€ë€«€É€Š€«€òÄŽ€Ù€ë¡£                     ****)
let rec solve_each_element iand_ofs and_group dirvec =
  let iobj = and_group.(iand_ofs) in
  if iobj = -1 then ()
  else (
    let t0 = solver iobj dirvec startp in
    if t0 <> 0 then
      (
       (* žòÅÀ€¬€¢€ë»þ€Ï¡¢€œ€ÎžòÅÀ€¬ÂŸ€ÎÍ×ÁÇ€ÎÃæ€ËŽÞ€Þ€ì€ë€«€É€Š€«ÄŽ€Ù€ë¡£*)
       (* º£€Þ€Ç€ÎÃæ€ÇºÇŸ®€Î t €ÎÃÍ€ÈÈæ€Ù€ë¡£*)
       let t0p = solver_dist.(0) in

       if (fless 0.0 t0p) then
	 if (fless t0p tmin.(0)) then
	   (
	    let t = t0p +. 0.01 in
	    let q0 = dirvec.(0) *. t +. startp.(0) in
	    let q1 = dirvec.(1) *. t +. startp.(1) in
	    let q2 = dirvec.(2) *. t +. startp.(2) in
	    if check_all_inside 0 and_group q0 q1 q2 then 
	      ( 
		tmin.(0) <- t;
		vecset intersection_point q0 q1 q2;
		intersected_object_id.(0) <- iobj;
		intsec_rectside.(0) <- t0
	       )
	    else ()
	   )
	 else ()
       else ();
       solve_each_element (iand_ofs + 1) and_group dirvec 
      )
    else
      (* žòÅÀ€¬€Ê€¯¡¢€·€«€â€œ€ÎÊªÂÎ€ÏÆâÂŠ€¬¿¿€Ê€é€³€ì°ÊŸåžòÅÀ€Ï€Ê€€ *)
      if o_isinvert (objects.(iobj)) then 
	solve_each_element (iand_ofs + 1) and_group dirvec
      else ()
	  
   )
in

(**** 1€Ä€Î OR-group €Ë€Ä€€€ÆžòÅÀ€òÄŽ€Ù€ë ****)
let rec solve_one_or_network ofs or_group dirvec =
  let head = or_group.(ofs) in
  if head <> -1 then (
    let and_group = and_net.(head) in
    solve_each_element 0 and_group dirvec;
    solve_one_or_network (ofs + 1) or_group dirvec
   ) else ()
in

(**** OR¥Þ¥È¥ê¥¯¥¹ÁŽÂÎ€Ë€Ä€€€ÆžòÅÀ€òÄŽ€Ù€ë¡£****)
let rec trace_or_matrix ofs or_network dirvec =
  let head = or_network.(ofs) in
  let range_primitive = head.(0) in
  if range_primitive = -1 then (* ÁŽ¥ª¥Ö¥ž¥§¥¯¥ÈœªÎ» *)
    ()
  else ( 
    if range_primitive = 99 (* range primitive €Ê€· *)
    then (solve_one_or_network 1 head dirvec)
    else 
      (
	(* range primitive €ÎŸ×ÆÍ€·€Ê€±€ì€ÐžòÅÀ€Ï€Ê€€ *)
       let t = solver range_primitive dirvec startp in
       if t <> 0 then
	 let tp = solver_dist.(0) in
	 if fless tp tmin.(0)
	 then (solve_one_or_network 1 head dirvec)
	 else ()
       else ()
      );
    trace_or_matrix (ofs + 1) or_network dirvec
  )
in

(**** ¥È¥ì¡Œ¥¹ËÜÂÎ ****)
(* ¥È¥ì¡Œ¥¹³«»ÏÅÀ ViewPoint €È¡¢€œ€ÎÅÀ€«€é€Î¥¹¥­¥ã¥óÊýžþ¥Ù¥¯¥È¥ë *)
(* Vscan €«€é¡¢žòÅÀ crashed_point €ÈŸ×ÆÍ€·€¿¥ª¥Ö¥ž¥§¥¯¥È         *)
(* crashed_object €òÊÖ€¹¡£ŽØ¿ôŒ«ÂÎ€ÎÊÖ€êÃÍ€ÏžòÅÀ€ÎÍ­Ìµ€Î¿¿µ¶ÃÍ¡£ *)
let rec judge_intersection dirvec = (
  tmin.(0) <- (1000000000.0);
  trace_or_matrix 0 (or_net.(0)) dirvec;
  let t = tmin.(0) in

  if (fless (-0.1) t) then
    (fless t 100000000.0)
  else false
 )
in

(******************************************************************************
   ž÷Àþ€ÈÊªÂÎ€Îžòº¹ÈœÄê ¹âÂ®ÈÇ
 *****************************************************************************)

let rec solve_each_element_fast iand_ofs and_group dirvec =
  let vec = (d_vec dirvec) in
  let iobj = and_group.(iand_ofs) in
  if iobj = -1 then ()
  else (
    let t0 = solver_fast2 iobj dirvec in
    if t0 <> 0 then
      (
        (* žòÅÀ€¬€¢€ë»þ€Ï¡¢€œ€ÎžòÅÀ€¬ÂŸ€ÎÍ×ÁÇ€ÎÃæ€ËŽÞ€Þ€ì€ë€«€É€Š€«ÄŽ€Ù€ë¡£*)
        (* º£€Þ€Ç€ÎÃæ€ÇºÇŸ®€Î t €ÎÃÍ€ÈÈæ€Ù€ë¡£*)
       let t0p = solver_dist.(0) in

       if (fless 0.0 t0p) then
	 if (fless t0p tmin.(0)) then
	   (
	    let t = t0p +. 0.01 in
	    let q0 = vec.(0) *. t +. startp_fast.(0) in
	    let q1 = vec.(1) *. t +. startp_fast.(1) in
	    let q2 = vec.(2) *. t +. startp_fast.(2) in
	    if check_all_inside 0 and_group q0 q1 q2 then 
	      ( 
		tmin.(0) <- t;
		vecset intersection_point q0 q1 q2;
		intersected_object_id.(0) <- iobj;
		intsec_rectside.(0) <- t0
	       )
	    else ()
	   )
	 else ()
       else ();
       solve_each_element_fast (iand_ofs + 1) and_group dirvec
      )
    else 
       (* žòÅÀ€¬€Ê€¯¡¢€·€«€â€œ€ÎÊªÂÎ€ÏÆâÂŠ€¬¿¿€Ê€é€³€ì°ÊŸåžòÅÀ€Ï€Ê€€ *)
       if o_isinvert (objects.(iobj)) then 
	 solve_each_element_fast (iand_ofs + 1) and_group dirvec
       else ()
   )   
in

(**** 1€Ä€Î OR-group €Ë€Ä€€€ÆžòÅÀ€òÄŽ€Ù€ë ****)
let rec solve_one_or_network_fast ofs or_group dirvec =
  let head = or_group.(ofs) in
  if head <> -1 then (
    let and_group = and_net.(head) in
    solve_each_element_fast 0 and_group dirvec;
    solve_one_or_network_fast (ofs + 1) or_group dirvec
   ) else ()
in

(**** OR¥Þ¥È¥ê¥¯¥¹ÁŽÂÎ€Ë€Ä€€€ÆžòÅÀ€òÄŽ€Ù€ë¡£****)
let rec trace_or_matrix_fast ofs or_network dirvec =
  let head = or_network.(ofs) in
  let range_primitive = head.(0) in
  if range_primitive = -1 then (* ÁŽ¥ª¥Ö¥ž¥§¥¯¥ÈœªÎ» *)
    ()
  else ( 
    if range_primitive = 99 (* range primitive €Ê€· *)
    then solve_one_or_network_fast 1 head dirvec
    else 
      (
	(* range primitive €ÎŸ×ÆÍ€·€Ê€±€ì€ÐžòÅÀ€Ï€Ê€€ *)
       let t = solver_fast2 range_primitive dirvec in
       if t <> 0 then
	 let tp = solver_dist.(0) in
	 if fless tp tmin.(0)
	 then (solve_one_or_network_fast 1 head dirvec)
	 else ()
       else ()
      );
    trace_or_matrix_fast (ofs + 1) or_network dirvec
   )
in

(**** ¥È¥ì¡Œ¥¹ËÜÂÎ ****)
let rec judge_intersection_fast dirvec =
( 
  tmin.(0) <- (1000000000.0);
  trace_or_matrix_fast 0 (or_net.(0)) dirvec;
  let t = tmin.(0) in

  if (fless (-0.1) t) then
    (fless t 100000000.0)
  else false
)
in

(******************************************************************************
   ÊªÂÎ€Èž÷€Îžòº¹ÅÀ€ÎË¡Àþ¥Ù¥¯¥È¥ë€òµá€á€ëŽØ¿ô
 *****************************************************************************)

(**** žòÅÀ€«€éË¡Àþ¥Ù¥¯¥È¥ë€ò·×»»€¹€ë ****)
(* Ÿ×ÆÍ€·€¿¥ª¥Ö¥ž¥§¥¯¥È€òµá€á€¿ºÝ€Î solver €ÎÊÖ€êÃÍ€ò *)
(* ÊÑ¿ô intsec_rectside ·ÐÍ³€ÇÅÏ€·€Æ€ä€ëÉ¬Í×€¬€¢€ë¡£  *)
(* nvector €â¥°¥í¡Œ¥Ð¥ë¡£ *)

let rec get_nvector_rect dirvec =
  let rectside = intsec_rectside.(0) in
  (* solver €ÎÊÖ€êÃÍ€Ï€Ö€Ä€«€Ã€¿ÌÌ€ÎÊýžþ€òŒš€¹ *)
  vecbzero nvector;
  nvector.(rectside-1) <- fneg (sgn (dirvec.(rectside-1)))
in

(* Ê¿ÌÌ *)
let rec get_nvector_plane m = 
  (* m_invert €ÏŸï€Ë true €Î€Ï€º *)
  nvector.(0) <- fneg (o_param_a m); (* if m_invert then fneg m_a else m_a *)
  nvector.(1) <- fneg (o_param_b m);
  nvector.(2) <- fneg (o_param_c m)
in

(* 2Œ¡¶ÊÌÌ :  grad x^t A x = 2 A x €òÀµµ¬²œ€¹€ë *)
let rec get_nvector_second m =
  let p0 = intersection_point.(0) -. o_param_x m in
  let p1 = intersection_point.(1) -. o_param_y m in
  let p2 = intersection_point.(2) -. o_param_z m in

  let d0 = p0 *. o_param_a m in
  let d1 = p1 *. o_param_b m in
  let d2 = p2 *. o_param_c m in

  if o_isrot m = 0 then (
    nvector.(0) <- d0;
    nvector.(1) <- d1;
    nvector.(2) <- d2
   ) else (
    nvector.(0) <- d0 +. fhalf (p1 *. o_param_r3 m +. p2 *. o_param_r2 m);
    nvector.(1) <- d1 +. fhalf (p0 *. o_param_r3 m +. p2 *. o_param_r1 m);
    nvector.(2) <- d2 +. fhalf (p0 *. o_param_r2 m +. p1 *. o_param_r1 m)
   );
  vecunit_sgn nvector (o_isinvert m)

in

let rec get_nvector m dirvec =
  let m_shape = o_form m in
  if m_shape = 1 then
    get_nvector_rect dirvec
  else if m_shape = 2 then
    get_nvector_plane m
  else (* 2Œ¡¶ÊÌÌ or ¿íÂÎ *)
    get_nvector_second m
  (* retval = nvector *)
in

(******************************************************************************
   ÊªÂÎÉœÌÌ€Î¿§(¿§ÉÕ€­³È»¶È¿ŒÍÎš)€òµá€á€ë
 *****************************************************************************)

(**** žòÅÀŸå€Î¥Æ¥¯¥¹¥Á¥ã€Î¿§€ò·×»»€¹€ë ****)
let rec utexture m p =
  let m_tex = o_texturetype m in
  (* ŽðËÜ€Ï¥ª¥Ö¥ž¥§¥¯¥È€Î¿§ *)
  texture_color.(0) <- o_color_red m;
  texture_color.(1) <- o_color_green m;
  texture_color.(2) <- o_color_blue m;
  if m_tex = 1 then
    (
     (* zxÊýžþ€Î¥Á¥§¥Ã¥«¡ŒÌÏÍÍ (G) *)
     let w1 = p.(0) -. o_param_x m in
     let flag1 =
       let d1 = (floor (w1 *. 0.05)) *. 20.0 in
      fless (w1 -. d1) 10.0
     in
     let w3 = p.(2) -. o_param_z m in
     let flag2 =
       let d2 = (floor (w3 *. 0.05)) *. 20.0 in
       fless (w3 -. d2) 10.0 
     in
     texture_color.(1) <-
       if flag1 
       then (if flag2 then 255.0 else 0.0)
       else (if flag2 then 0.0 else 255.0)
    )
  else if m_tex = 2 then
    (* yŒŽÊýžþ€Î¥¹¥È¥é¥€¥× (R-G) *)
    (
      let w2 = fsqr (sin (p.(1) *. 0.25)) in
      texture_color.(0) <- 255.0 *. w2;
      texture_color.(1) <- 255.0 *. (1.0 -. w2)
    )
  else if m_tex = 3 then 
    (* ZXÌÌÊýžþ€ÎÆ±¿Ž±ß (G-B) *)
    ( 
      let w1 = p.(0) -. o_param_x m in
      let w3 = p.(2) -. o_param_z m in
      let w2 = sqrt (fsqr w1 +. fsqr w3) /. 10.0 in
      let w4 =  (w2 -. floor w2) *. 3.1415927 in
      let cws = fsqr (cos w4) in
      texture_color.(1) <- cws *. 255.0;
      texture_color.(2) <- (1.0 -. cws) *. 255.0
    )
  else if m_tex = 4 then (
    (* µåÌÌŸå€ÎÈÃÅÀ (B) *)
    let w1 = (p.(0) -. o_param_x m) *. (sqrt (o_param_a m)) in
    let w3 = (p.(2) -. o_param_z m) *. (sqrt (o_param_c m)) in
    let w4 = (fsqr w1) +. (fsqr w3) in
    let w7 = 
      if fless (fabs w1) 1.0e-4 then
	15.0 (* atan +infty = pi/2 *)
      else
	let w5 = fabs (w3 /. w1)
	in
	((atan w5) *. 30.0) /. 3.1415927 
    in
    let w9 = w7 -. (floor w7) in

    let w2 = (p.(1) -. o_param_y m) *. (sqrt (o_param_b m)) in
    let w8 =
      if fless (fabs w4) 1.0e-4 then
	15.0
      else 
	let w6 = fabs (w2 /. w4)
	in ((atan w6) *. 30.0) /. 3.1415927 
    in
    let w10 = w8 -. (floor w8) in
    let w11 = 0.15 -. (fsqr (0.5 -. w9)) -. (fsqr (0.5 -. w10)) in
    let w12 = if fisneg w11 then 0.0 else w11 in
    texture_color.(2) <- (255.0 *. w12) /. 0.3
   )
  else ()
in

(******************************************************************************
   Ÿ×ÆÍÅÀ€ËÅö€¿€ëž÷ž»€ÎÄŸÀÜž÷€ÈÈ¿ŒÍž÷€ò·×»»€¹€ëŽØ¿ô·² 
 *****************************************************************************)

(* Åö€¿€Ã€¿ž÷€Ë€è€ë³È»¶ž÷€ÈÉÔŽ°ÁŽ¶ÀÌÌÈ¿ŒÍž÷€Ë€è€ëŽóÍ¿€òRGBÃÍ€Ë²Ã»» *)
let rec add_light bright hilight hilight_scale =

  (* ³È»¶ž÷ *)
  if fispos bright then
    vecaccum rgb bright texture_color
  else ();

  (* ÉÔŽ°ÁŽ¶ÀÌÌÈ¿ŒÍ cos ^4 ¥â¥Ç¥ë *)
  if fispos hilight then (
    let ihl = fsqr (fsqr hilight) *. hilight_scale in
    rgb.(0) <- rgb.(0) +. ihl;
    rgb.(1) <- rgb.(1) +. ihl;
    rgb.(2) <- rgb.(2) +. ihl
  ) else ()
in

(* ³ÆÊªÂÎ€Ë€è€ëž÷ž»€ÎÈ¿ŒÍž÷€ò·×»»€¹€ëŽØ¿ô(ÄŸÊýÂÎ€ÈÊ¿ÌÌ€Î€ß) *)
let rec trace_reflections index diffuse hilight_scale dirvec =

  if index >= 0 then (
    let rinfo = reflections.(index) in (* ¶ÀÊ¿ÌÌ€ÎÈ¿ŒÍŸðÊó *)
    let dvec = r_dvec rinfo in    (* È¿ŒÍž÷€ÎÊýžþ¥Ù¥¯¥È¥ë(ž÷€ÈµÕžþ€­ *)

    (*È¿ŒÍž÷€òµÕ€Ë€¿€É€ê¡¢ŒÂºÝ€Ë€œ€Î¶ÀÌÌ€ËÅö€¿€ì€Ð¡¢È¿ŒÍž÷€¬ÆÏ€¯²ÄÇœÀ­Í­€ê *)
    if judge_intersection_fast dvec then
      let surface_id = intersected_object_id.(0) * 4 + intsec_rectside.(0) in
      if surface_id = r_surface_id rinfo then
	(* ¶ÀÌÌ€È€ÎŸ×ÆÍÅÀ€¬ž÷ž»€Î±Æ€Ë€Ê€Ã€Æ€€€Ê€±€ì€ÐÈ¿ŒÍž÷€ÏÆÏ€¯ *)
        if not (shadow_check_one_or_matrix 0 or_net.(0)) then
	  (* ÆÏ€€€¿È¿ŒÍž÷€Ë€è€ë RGBÀ®Ê¬€Ø€ÎŽóÍ¿€ò²Ã»» *)
          let p = veciprod nvector (d_vec dvec) in
          let scale = r_bright rinfo in
          let bright = scale *. diffuse *. p in
          let hilight = scale *. veciprod dirvec (d_vec dvec) in
          add_light bright hilight hilight_scale
        else ()
      else ()
    else ();
    trace_reflections (index - 1) diffuse hilight_scale dirvec
  ) else ()

in

(******************************************************************************
   ÄŸÀÜž÷€òÄÉÀ×€¹€ë
 *****************************************************************************)
let rec trace_ray nref energy dirvec pixel dist =
  if nref <= 4 then (
    let surface_ids = p_surface_ids pixel in
    if judge_intersection dirvec then (
    (* ¥ª¥Ö¥ž¥§¥¯¥È€Ë€Ö€Ä€«€Ã€¿Ÿì¹ç *)
      let obj_id = intersected_object_id.(0) in
      let obj = objects.(obj_id) in
      let m_surface = o_reflectiontype obj in
      let diffuse = o_diffuse obj *. energy in

      get_nvector obj dirvec; (* Ë¡Àþ¥Ù¥¯¥È¥ë€ò get *)
      veccpy startp intersection_point;  (* žòº¹ÅÀ€ò¿·€¿€Êž÷€ÎÈ¯ŒÍÅÀ€È€¹€ë *)
      utexture obj intersection_point; (*¥Æ¥¯¥¹¥Á¥ã€ò·×»» *)
      
      (* pixel tuple€ËŸðÊó€ò³ÊÇŒ€¹€ë *)
      surface_ids.(nref) <- obj_id * 4 + intsec_rectside.(0);
      let intersection_points = p_intersection_points pixel in
      veccpy intersection_points.(nref) intersection_point;
      
      (* ³È»¶È¿ŒÍÎš€¬0.5°ÊŸå€ÎŸì¹ç€Î€ßŽÖÀÜž÷€Î¥µ¥ó¥×¥ê¥ó¥°€ò¹Ô€Š *)
      let calc_diffuse = p_calc_diffuse pixel in
      if fless (o_diffuse obj) 0.5 then 
	calc_diffuse.(nref) <- false
      else (
	calc_diffuse.(nref) <- true;
	let energya = p_energy pixel in
	veccpy energya.(nref) texture_color;
	vecscale energya.(nref) ((1.0 /. 256.0) *. diffuse);
	let nvectors = p_nvectors pixel in
	veccpy nvectors.(nref) nvector
       );

      let w = (-2.0) *. veciprod dirvec nvector in
      (* È¿ŒÍž÷€ÎÊýžþ€Ë¥È¥ì¡Œ¥¹Êýžþ€òÊÑ¹¹ *)
      vecaccum dirvec w nvector;

      let hilight_scale = energy *. o_hilight obj in

      (* ž÷ž»ž÷€¬ÄŸÀÜÆÏ€¯Ÿì¹ç¡¢RGBÀ®Ê¬€Ë€³€ì€ò²ÃÌ£€¹€ë *)
      if not (shadow_check_one_or_matrix 0 or_net.(0)) then
        let bright = fneg (veciprod nvector light) *. diffuse in
        let hilight = fneg (veciprod dirvec light) in
        add_light bright hilight hilight_scale
      else ();

      (* ž÷ž»ž÷€ÎÈ¿ŒÍž÷€¬Ìµ€€€«Ãµ€¹ *)
      setup_startp intersection_point;
      trace_reflections (n_reflections.(0)-1) diffuse hilight_scale dirvec;

      (* œÅ€ß€¬ 0.1€è€êÂ¿€¯»Ä€Ã€Æ€€€¿€é¡¢¶ÀÌÌÈ¿ŒÍžµ€òÄÉÀ×€¹€ë *)
      if fless 0.1 energy then ( 
	
	if(nref < 4) then
	  surface_ids.(nref+1) <- -1
	else ();
	
	if m_surface = 2 then (   (* Ž°ÁŽ¶ÀÌÌÈ¿ŒÍ *)
	  let energy2 = energy *. (1.0 -. o_diffuse obj) in
	  trace_ray (nref+1) energy2 dirvec pixel (dist +. tmin.(0))
	 ) else ()
	
       ) else ()
      
     ) else ( 
      (* €É€ÎÊªÂÎ€Ë€âÅö€¿€é€Ê€«€Ã€¿Ÿì¹ç¡£ž÷ž»€«€é€Îž÷€ò²ÃÌ£ *)

      surface_ids.(nref) <- -1;

      if nref <> 0 then (
	let hl = fneg (veciprod dirvec light) in
        (* 90¡ë€òÄ¶€š€ëŸì¹ç€Ï0 (ž÷€Ê€·) *)
	if fispos hl then
	  (
	   (* ¥Ï¥€¥é¥€¥È¶¯ÅÙ€Ï³ÑÅÙ€Î cos^3 €ËÈæÎã *)
	   let ihl = fsqr hl *. hl *. energy *. beam.(0) in
	   rgb.(0) <- rgb.(0) +. ihl;
	   rgb.(1) <- rgb.(1) +. ihl;
	   rgb.(2) <- rgb.(2) +. ihl
          )
	else ()
       ) else ()
     )
   ) else ()
in


(******************************************************************************
   ŽÖÀÜž÷€òÄÉÀ×€¹€ë
 *****************************************************************************)

(* €¢€ëÅÀ€¬ÆÃÄê€ÎÊýžþ€«€éŒõ€±€ëŽÖÀÜž÷€Î¶¯€µ€ò·×»»€¹€ë *)
(* ŽÖÀÜž÷€ÎÊýžþ¥Ù¥¯¥È¥ë dirvec€ËŽØ€·€Æ€ÏÄê¿ô¥Æ¡Œ¥Ö¥ë€¬ºî€é€ì€Æ€ª€ê¡¢Ÿ×ÆÍÈœÄê
   €¬¹âÂ®€Ë¹Ô€ï€ì€ë¡£ÊªÂÎ€ËÅö€¿€Ã€¿€é¡¢€œ€Îžå€ÎÈ¿ŒÍ€ÏÄÉÀ×€·€Ê€€ *)
let rec trace_diffuse_ray dirvec energy =
 
  (* €É€ì€«€ÎÊªÂÎ€ËÅö€¿€ë€«ÄŽ€Ù€ë *)
  if judge_intersection_fast dirvec then
    let obj = objects.(intersected_object_id.(0)) in
    get_nvector obj (d_vec dirvec); 
    utexture obj intersection_point;      

    (* €œ€ÎÊªÂÎ€¬ÊüŒÍ€¹€ëž÷€Î¶¯€µ€òµá€á€ë¡£ÄŸÀÜž÷ž»ž÷€Î€ß€ò·×»» *)
    if not (shadow_check_one_or_matrix 0 or_net.(0)) then 
      let br =  fneg (veciprod nvector light) in
      let bright = (if fispos br then br else 0.0) in
      vecaccum diffuse_ray (energy *. bright *. o_diffuse obj) texture_color
    else ()
  else ()
in

(* €¢€é€«€ž€á·è€á€é€ì€¿Êýžþ¥Ù¥¯¥È¥ë€ÎÇÛÎó€ËÂÐ€·¡¢³Æ¥Ù¥¯¥È¥ë€ÎÊý³Ñ€«€éÍè€ë
   ŽÖÀÜž÷€Î¶¯€µ€ò¥µ¥ó¥×¥ê¥ó¥°€·€Æ²Ã»»€¹€ë *)
let rec iter_trace_diffuse_rays dirvec_group nvector org index = 
  if index >= 0 then (
    let p = veciprod (d_vec dirvec_group.(index)) nvector in

    (* ÇÛÎó€Î 2n ÈÖÌÜ€È 2n+1 ÈÖÌÜ€Ë€Ïžß€€€ËµÕžþ€ÎÊýžþ¥Ù¥¯¥È¥ë€¬Æþ€Ã€Æ€€€ë
       Ë¡Àþ¥Ù¥¯¥È¥ë€ÈÆ±€žžþ€­€ÎÊª€òÁª€ó€Ç»È€Š *)
    if fisneg p then
      trace_diffuse_ray dirvec_group.(index + 1) (p /. -150.0)
    else 
      trace_diffuse_ray dirvec_group.(index) (p /. 150.0);
	
    iter_trace_diffuse_rays dirvec_group nvector org (index - 2)
   ) else ()
in

(* Í¿€š€é€ì€¿Êýžþ¥Ù¥¯¥È¥ë€Îœž¹ç€ËÂÐ€·¡¢€œ€ÎÊýžþ€ÎŽÖÀÜž÷€ò¥µ¥ó¥×¥ê¥ó¥°€¹€ë *)
let rec trace_diffuse_rays dirvec_group nvector org =
  setup_startp org;
  (* ÇÛÎó€Î 2n ÈÖÌÜ€È 2n+1 ÈÖÌÜ€Ë€Ïžß€€€ËµÕžþ€ÎÊýžþ¥Ù¥¯¥È¥ë€¬Æþ€Ã€Æ€€€Æ¡¢
     Ë¡Àþ¥Ù¥¯¥È¥ë€ÈÆ±€žžþ€­€ÎÊª€Î€ß¥µ¥ó¥×¥ê¥ó¥°€Ë»È€ï€ì€ë *)
  (* ÁŽÉô€Ç 120 / 2 = 60ËÜ€Î¥Ù¥¯¥È¥ë€òÄÉÀ× *)
  iter_trace_diffuse_rays dirvec_group nvector org 118
in

(* ÈŸµåÊýžþ€ÎÁŽÉô€Ç300ËÜ€Î¥Ù¥¯¥È¥ë€Î€Š€Á¡¢€Þ€ÀÄÉÀ×€·€Æ€€€Ê€€»Ä€ê€Î240ËÜ€Î
   ¥Ù¥¯¥È¥ë€Ë€Ä€€€ÆŽÖÀÜž÷ÄÉÀ×€¹€ë¡£60ËÜ€Î¥Ù¥¯¥È¥ëÄÉÀ×€ò4¥»¥Ã¥È¹Ô€Š *)
let rec trace_diffuse_ray_80percent group_id nvector org = 

  if group_id <> 0 then 
    trace_diffuse_rays dirvecs.(0) nvector org
  else ();

  if group_id <> 1 then
    trace_diffuse_rays dirvecs.(1) nvector org
  else ();
  
  if group_id <> 2 then
    trace_diffuse_rays dirvecs.(2) nvector org
  else ();
  
  if group_id <> 3 then
    trace_diffuse_rays dirvecs.(3) nvector org
  else ();
  
  if group_id <> 4 then
    trace_diffuse_rays dirvecs.(4) nvector org
  else ()
  
in

(* Ÿå²Œºž±Š4ÅÀ€ÎŽÖÀÜž÷ÄÉÀ×·ë²Ì€ò»È€ï€º¡¢300ËÜÁŽÉô€Î¥Ù¥¯¥È¥ë€òÄÉÀ×€·€ÆŽÖÀÜž÷€ò
   ·×»»€¹€ë¡£20%(60ËÜ)€ÏÄÉÀ×ºÑ€Ê€Î€Ç¡¢»Ä€ê80%(240ËÜ)€òÄÉÀ×€¹€ë *)
let rec calc_diffuse_using_1point pixel nref = 
  
  let ray20p = p_received_ray_20percent pixel in
  let nvectors = p_nvectors pixel in
  let intersection_points = p_intersection_points pixel in
  let energya = p_energy pixel in

  veccpy diffuse_ray ray20p.(nref);
  trace_diffuse_ray_80percent 
    (p_group_id pixel)
    nvectors.(nref)
    intersection_points.(nref);
  vecaccumv rgb energya.(nref) diffuse_ray
    
in

(* Œ«Ê¬€ÈŸå²Œºž±Š4ÅÀ€ÎÄÉÀ×·ë²Ì€ò²Ã»»€·€ÆŽÖÀÜž÷€òµá€á€ë¡£ËÜÍè€Ï 300 ËÜ€Îž÷€ò
   ÄÉÀ×€¹€ëÉ¬Í×€¬€¢€ë€¬¡¢5ÅÀ²Ã»»€¹€ë€Î€Ç1ÅÀ€¢€¿€ê60ËÜ(20%)ÄÉÀ×€¹€ë€À€±€ÇºÑ€à *)
   
let rec calc_diffuse_using_5points x prev cur next nref =

  let r_up = p_received_ray_20percent prev.(x) in
  let r_left = p_received_ray_20percent cur.(x-1) in
  let r_center = p_received_ray_20percent cur.(x) in
  let r_right = p_received_ray_20percent cur.(x+1) in
  let r_down = p_received_ray_20percent next.(x) in
  
  veccpy diffuse_ray r_up.(nref);
  vecadd diffuse_ray r_left.(nref);
  vecadd diffuse_ray r_center.(nref);
  vecadd diffuse_ray r_right.(nref);
  vecadd diffuse_ray r_down.(nref);
  
  let energya = p_energy cur.(x) in
  vecaccumv rgb energya.(nref) diffuse_ray
  
in

(* Ÿå²Œºž±Š4ÅÀ€ò»È€ï€º€ËÄŸÀÜž÷€Î³ÆŸ×ÆÍÅÀ€Ë€ª€±€ëŽÖÀÜŒõž÷€ò·×»»€¹€ë *)
let rec do_without_neighbors pixel nref = 
  if nref <= 4 then
    (* Ÿ×ÆÍÌÌÈÖ¹æ€¬Í­žú(ÈóÉé)€«¥Á¥§¥Ã¥¯ *)
    let surface_ids = p_surface_ids pixel in
    if surface_ids.(nref) >= 0 then (
      let calc_diffuse = p_calc_diffuse pixel in
      if calc_diffuse.(nref) then
	calc_diffuse_using_1point pixel nref
      else ();
      do_without_neighbors pixel (nref + 1)
     ) else ()
  else ()
in

(* ²èÁüŸå€ÇŸå²Œºž±Š€ËÅÀ€¬€¢€ë€«(Í×€¹€ë€Ë¡¢²èÁü€ÎÃŒ€ÇÌµ€€»ö)€ò³ÎÇ§ *)
let rec neighbors_exist x y next =
  if (y + 1) < image_size.(1) then 
    if y > 0 then
      if (x + 1) < image_size.(0) then
	if x > 0 then
	  true
	else false
      else false
    else false
  else false
in

let rec get_surface_id pixel index =
  let surface_ids = p_surface_ids pixel in
  surface_ids.(index)
in

(* Ÿå²Œºž±Š4ÅÀ€ÎÄŸÀÜž÷ÄÉÀ×€Î·ë²Ì¡¢Œ«Ê¬€ÈÆ±€žÌÌ€ËŸ×ÆÍ€·€Æ€€€ë€«€ò¥Á¥§¥Ã¥¯
   €â€·Æ±€žÌÌ€ËŸ×ÆÍ€·€Æ€€€ì€Ð¡¢€³€ì€é4ÅÀ€Î·ë²Ì€ò»È€Š€³€È€Ç·×»»€òŸÊÎ¬œÐÍè€ë *)
let rec neighbors_are_available x prev cur next nref =
  let sid_center = get_surface_id cur.(x) nref in

  if get_surface_id prev.(x) nref = sid_center then
    if get_surface_id next.(x) nref = sid_center then
      if get_surface_id cur.(x-1) nref = sid_center then
	if get_surface_id cur.(x+1) nref = sid_center then
	  true
	else false
      else false
    else false
  else false
in

(* ÄŸÀÜž÷€Î³ÆŸ×ÆÍÅÀ€Ë€ª€±€ëŽÖÀÜŒõž÷€Î¶¯€µ€ò¡¢Ÿå²Œºž±Š4ÅÀ€Î·ë²Ì€ò»ÈÍÑ€·€Æ·×»»
   €¹€ë¡£€â€·Ÿå²Œºž±Š4ÅÀ€Î·×»»·ë²Ì€ò»È€š€Ê€€Ÿì¹ç€Ï¡¢€œ€Î»þÅÀ€Ç
   do_without_neighbors€ËÀÚ€êÂØ€š€ë *)

let rec try_exploit_neighbors x y prev cur next nref =
  let pixel = cur.(x) in
  if nref <= 4 then

    (* Ÿ×ÆÍÌÌÈÖ¹æ€¬Í­žú(ÈóÉé)€« *)
    if get_surface_id pixel nref >= 0 then
      (* Œþ°Ï4ÅÀ€òÊäŽ°€Ë»È€š€ë€« *)
      if neighbors_are_available x prev cur next nref then (

	(* ŽÖÀÜŒõž÷€ò·×»»€¹€ë¥Õ¥é¥°€¬Î©€Ã€Æ€€€ì€ÐŒÂºÝ€Ë·×»»€¹€ë *)
	let calc_diffuse = p_calc_diffuse pixel in
        if calc_diffuse.(nref) then
	  calc_diffuse_using_5points x prev cur next nref
	else ();

	(* Œ¡€ÎÈ¿ŒÍŸ×ÆÍÅÀ€Ø *)
	try_exploit_neighbors x y prev cur next (nref + 1)
      ) else
	(* Œþ°Ï4ÅÀ€òÊäŽ°€Ë»È€š€Ê€€€Î€Ç¡¢€³€ì€é€ò»È€ï€Ê€€ÊýË¡€ËÀÚ€êÂØ€š€ë *)
	do_without_neighbors cur.(x) nref
    else ()
  else ()
in

(******************************************************************************
   PPM¥Õ¥¡¥€¥ë€Îœñ€­¹þ€ßŽØ¿ô
 *****************************************************************************)
let rec write_ppm_header _ =
  ( 
    print_char 80; (* 'P' *)
    print_char (48 + 3); (* +6 if binary *) (* 48 = '0' *)
    print_char 10;
    print_int image_size.(0);
    print_char 32;
    print_int image_size.(1);
    print_char 32;
    print_int 255;
    print_char 10
  )
in

let rec write_rgb_element x =
  let ix = int_of_float x in
  let elem = if ix > 255 then 255 else if ix < 0 then 0 else ix in
  print_int elem
in

let rec write_rgb _ =
   write_rgb_element rgb.(0); (* Red   *)
   print_char 32;
   write_rgb_element rgb.(1); (* Green *)
   print_char 32;
   write_rgb_element rgb.(2); (* Blue  *)
   print_char 10
in

(******************************************************************************
   €¢€ë¥é¥€¥ó€Î·×»»€ËÉ¬Í×€ÊŸðÊó€òœž€á€ë€¿€áŒ¡€Î¥é¥€¥ó€ÎÄÉÀ×€ò¹Ô€Ã€Æ€ª€¯ŽØ¿ô·²
 *****************************************************************************)

(* ŽÖÀÜž÷€Î¥µ¥ó¥×¥ê¥ó¥°€Ç€ÏŸå²Œºž±Š4ÅÀ€Î·ë²Ì€ò»È€Š€Î€Ç¡¢Œ¡€Î¥é¥€¥ó€Î·×»»€ò
   ¹Ô€ï€Ê€€€ÈºÇœªÅª€Ê¥Ô¥¯¥»¥ë€ÎÃÍ€ò·×»»€Ç€­€Ê€€ *)

(* ŽÖÀÜž÷€ò 60ËÜ(20%)€À€±·×»»€·€Æ€ª€¯ŽØ¿ô *)
let rec pretrace_diffuse_rays pixel nref =
  if nref <= 4 then

    (* ÌÌÈÖ¹æ€¬Í­žú€« *)
    let sid = get_surface_id pixel nref in
    if sid >= 0 then (
      (* ŽÖÀÜž÷€ò·×»»€¹€ë¥Õ¥é¥°€¬Î©€Ã€Æ€€€ë€« *)
      let calc_diffuse = p_calc_diffuse pixel in
      if calc_diffuse.(nref) then (
	let group_id = p_group_id pixel in
	vecbzero diffuse_ray;

	(* 5€Ä€ÎÊýžþ¥Ù¥¯¥È¥ëœž¹ç(³Æ60ËÜ)€«€éŒ«Ê¬€Î¥°¥ë¡Œ¥×ID€ËÂÐ±þ€¹€ëÊª€ò
	   °ì€ÄÁª€ó€ÇÄÉÀ× *)
	let nvectors = p_nvectors pixel in
	let intersection_points = p_intersection_points pixel in
	trace_diffuse_rays 
	  dirvecs.(group_id) 
	  nvectors.(nref)
	  intersection_points.(nref);
	let ray20p = p_received_ray_20percent pixel in
	veccpy ray20p.(nref) diffuse_ray
       ) else ();
      pretrace_diffuse_rays pixel (nref + 1)
     ) else ()
  else ()
in

(* ³Æ¥Ô¥¯¥»¥ë€ËÂÐ€·€ÆÄŸÀÜž÷ÄÉÀ×€ÈŽÖÀÜŒõž÷€Î20%Ê¬€Î·×»»€ò¹Ô€Š *)

let rec pretrace_pixels line x group_id lc0 lc1 lc2 = 
  if x >= 0 then (

    let xdisp = scan_pitch.(0) *. float_of_int (x - image_center.(0)) in
    ptrace_dirvec.(0) <- xdisp *. screenx_dir.(0) +. lc0;
    ptrace_dirvec.(1) <- xdisp *. screenx_dir.(1) +. lc1;
    ptrace_dirvec.(2) <- xdisp *. screenx_dir.(2) +. lc2;
    vecunit_sgn ptrace_dirvec false;
    vecbzero rgb;
    veccpy startp viewpoint;

    (* ÄŸÀÜž÷ÄÉÀ× *)
    trace_ray 0 1.0 ptrace_dirvec line.(x) 0.0;
    veccpy (p_rgb line.(x)) rgb;
    p_set_group_id line.(x) group_id;
    
    (* ŽÖÀÜž÷€Î20%€òÄÉÀ× *)
    pretrace_diffuse_rays line.(x) 0;
    
    pretrace_pixels line (x-1) (add_mod5 group_id 1) lc0 lc1 lc2
    
   ) else ()
in

(* €¢€ë¥é¥€¥ó€Î³Æ¥Ô¥¯¥»¥ë€ËÂÐ€·ÄŸÀÜž÷ÄÉÀ×€ÈŽÖÀÜŒõž÷20%Ê¬€Î·×»»€ò€¹€ë *)
let rec pretrace_line line y group_id = 
  let ydisp = scan_pitch.(0) *. float_of_int (y - image_center.(1)) in
 
  (* ¥é¥€¥ó€ÎÃæ¿Ž€Ëžþ€«€Š¥Ù¥¯¥È¥ë€ò·×»» *)
  let lc0 = ydisp *. screeny_dir.(0) +. screenz_dir.(0) in
  let lc1 = ydisp *. screeny_dir.(1) +. screenz_dir.(1) in
  let lc2 = ydisp *. screeny_dir.(2) +. screenz_dir.(2) in
  pretrace_pixels line (image_size.(0) - 1) group_id lc0 lc1 lc2
in


(******************************************************************************
   ÄŸÀÜž÷ÄÉÀ×€ÈŽÖÀÜž÷20%ÄÉÀ×€Î·ë²Ì€«€éºÇœªÅª€Ê¥Ô¥¯¥»¥ëÃÍ€ò·×»»€¹€ëŽØ¿ô
 *****************************************************************************)

(* ³Æ¥Ô¥¯¥»¥ë€ÎºÇœªÅª€Ê¥Ô¥¯¥»¥ëÃÍ€ò·×»» *)
let rec scan_pixel x y prev cur next = 
  if x < image_size.(0) then (

    (* €Þ€º¡¢ÄŸÀÜž÷ÄÉÀ×€ÇÆÀ€é€ì€¿RGBÃÍ€òÆÀ€ë *)
    veccpy rgb (p_rgb cur.(x));

    (* Œ¡€Ë¡¢ÄŸÀÜž÷€Î³ÆŸ×ÆÍÅÀ€Ë€Ä€€€Æ¡¢ŽÖÀÜŒõž÷€Ë€è€ëŽóÍ¿€ò²ÃÌ£€¹€ë *)
    if neighbors_exist x y next then
      try_exploit_neighbors x y prev cur next 0
    else
      do_without_neighbors cur.(x) 0;

    (* ÆÀ€é€ì€¿ÃÍ€òPPM¥Õ¥¡¥€¥ë€ËœÐÎÏ *)
    write_rgb ();

    scan_pixel (x + 1) y prev cur next
   ) else ()
in

(* °ì¥é¥€¥óÊ¬€Î¥Ô¥¯¥»¥ëÃÍ€ò·×»» *)
let rec scan_line y prev cur next group_id = (

  if y < image_size.(1) then (

    if y < image_size.(1) - 1 then
      pretrace_line next (y + 1) group_id
    else ();
    scan_pixel 0 y prev cur next;
    scan_line (y + 1) cur next prev (add_mod5 group_id 2)
   ) else ()      
)
in

(******************************************************************************
   ¥Ô¥¯¥»¥ë€ÎŸðÊó€ò³ÊÇŒ€¹€ë¥Ç¡Œ¥¿¹œÂ€€Î³ä€êÅö€ÆŽØ¿ô·²
 *****************************************************************************)

(* 3Œ¡žµ¥Ù¥¯¥È¥ë€Î5Í×ÁÇÇÛÎó€ò³ä€êÅö€Æ *)
let rec create_float5x3array _ = (
  let vec = Array.create 3 0.0 in
  let array = Array.create 5 vec in
  array.(1) <- Array.create 3 0.0;
  array.(2) <- Array.create 3 0.0;
  array.(3) <- Array.create 3 0.0;
  array.(4) <- Array.create 3 0.0;
  array
)
in

(* ¥Ô¥¯¥»¥ë€òÉœ€¹tuple€ò³ä€êÅö€Æ *)
let rec create_pixel _ =
  let m_rgb = Array.create 3 0.0 in
  let m_isect_ps = create_float5x3array() in
  let m_sids = Array.create 5 0 in
  let m_cdif = Array.create 5 false in
  let m_engy = create_float5x3array() in
  let m_r20p = create_float5x3array() in
  let m_gid = Array.create 1 0 in
  let m_nvectors = create_float5x3array() in
  (m_rgb, m_isect_ps, m_sids, m_cdif, m_engy, m_r20p, m_gid, m_nvectors)
in

(* ²£Êýžþ1¥é¥€¥óÃæ€Î³Æ¥Ô¥¯¥»¥ëÍ×ÁÇ€ò³ä€êÅö€Æ€ë *)
let rec init_line_elements line n =
  if n >= 0 then (
    line.(n) <- create_pixel();
    init_line_elements line (n-1)
   ) else
    line
in

(* ²£Êýžþ1¥é¥€¥óÊ¬€Î¥Ô¥¯¥»¥ëÇÛÎó€òºî€ë *)
let rec create_pixelline _ = 
  let line = Array.create image_size.(0) (create_pixel()) in
  init_line_elements line (image_size.(0)-2)
in

(******************************************************************************
   ŽÖÀÜž÷€Î¥µ¥ó¥×¥ê¥ó¥°€Ë€Ä€«€ŠÊýžþ¥Ù¥¯¥È¥ë·²€ò·×»»€¹€ëŽØ¿ô·²
 *****************************************************************************)

(* ¥Ù¥¯¥È¥ëÃ£€¬œÐÍè€ë€À€±°ìÍÍ€ËÊ¬ÉÛ€¹€ë€è€Š¡¢600ËÜ€ÎÊýžþ¥Ù¥¯¥È¥ë€Îžþ€­€òÄê€á€ë
   Î©ÊýÂÎŸå€Î³ÆÌÌ€Ë100ËÜ€º€ÄÊ¬ÉÛ€µ€»¡¢€µ€é€Ë¡¢100ËÜ€¬Î©ÊýÂÎŸå€ÎÌÌŸå€Ç10 x 10 €Î
   ³Ê»ÒŸõ€ËÊÂ€Ö€è€Š€ÊÇÛÎó€ò»È€Š¡£€³€ÎÇÛÎó€Ç€ÏÊý³Ñ€Ë€è€ë¥Ù¥¯¥È¥ë€ÎÌ©ÅÙ€Îº¹€¬
   Âç€­€€€Î€Ç¡¢€³€ì€ËÊäÀµ€ò²Ã€š€¿€â€Î€òºÇœªÅª€ËÍÑ€€€ë *)
(*
let rec tan x =
  sin(x) /. cos(x)
in
*)
(* ¥Ù¥¯¥È¥ëÃ£€¬œÐÍè€ë€À€±µåÌÌŸõ€Ë°ìÍÍ€ËÊ¬ÉÛ€¹€ë€è€ŠºÂÉž€òÊäÀµ€¹€ë *)
let rec adjust_position h ratio =
  let l = sqrt(h*.h +. 0.1) in
  let tan_h = 1.0 /. l in
  let theta_h = atan tan_h in
   let tan_m = tan (theta_h *. ratio) in
  tan_m *. l
in

(* ¥Ù¥¯¥È¥ëÃ£€¬œÐÍè€ë€À€±µåÌÌŸõ€Ë°ìÍÍ€ËÊ¬ÉÛ€¹€ë€è€Š€Êžþ€­€ò·×»»€¹€ë *)
let rec calc_dirvec icount x y rx ry group_id index =
  if icount >= 5 then (
    let l = sqrt(fsqr x +. fsqr y +. 1.0) in
    let vx = x /. l in
    let vy = y /. l in
    let vz = 1.0 /. l in

    (* Î©ÊýÂÎÅª€ËÂÐŸÎ€ËÊ¬ÉÛ€µ€»€ë *)
    let dgroup = dirvecs.(group_id) in
    vecset (d_vec dgroup.(index))    vx vy vz;
    vecset (d_vec dgroup.(index+40)) vx vz (fneg vy);
    vecset (d_vec dgroup.(index+80)) vz (fneg vx) (fneg vy);
    vecset (d_vec dgroup.(index+1)) (fneg vx) (fneg vy) (fneg vz);
    vecset (d_vec dgroup.(index+41)) (fneg vx) (fneg vz) vy;
    vecset (d_vec dgroup.(index+81)) (fneg vz) vx vy
   ) else 
    let x2 = adjust_position y rx in
    calc_dirvec (icount + 1) x2 (adjust_position x2 ry) rx ry group_id index
in

(* Î©ÊýÂÎŸå€Î 10x10³Ê»Ò€Î¹ÔÃæ€Î³Æ¥Ù¥¯¥È¥ë€ò·×»»€¹€ë *)
let rec calc_dirvecs col ry group_id index =
  if col >= 0 then (
    (* ºžÈŸÊ¬ *)
    let rx = (float_of_int col) *. 0.2 -. 0.9 in (* Îó€ÎºÂÉž *)
    calc_dirvec 0 0.0 0.0 rx ry group_id index;
    (* ±ŠÈŸÊ¬ *)
    let rx2 = (float_of_int col) *. 0.2 +. 0.1 in (* Îó€ÎºÂÉž *)
    calc_dirvec 0 0.0 0.0 rx2 ry group_id (index + 2);

    calc_dirvecs (col - 1) ry (add_mod5 group_id 1) index
   ) else ()
in

(* Î©ÊýÂÎŸå€Î10x10³Ê»Ò€Î³Æ¹Ô€ËÂÐ€·¥Ù¥¯¥È¥ë€Îžþ€­€ò·×»»€¹€ë *)
let rec calc_dirvec_rows row group_id index =
  if row >= 0 then (
    let ry = (float_of_int row) *. 0.2 -. 0.9 in (* ¹Ô€ÎºÂÉž *)
    calc_dirvecs 4 ry group_id index; (* °ì¹ÔÊ¬·×»» *)
    calc_dirvec_rows (row - 1) (add_mod5 group_id 2) (index + 4) 
   ) else ()
in

(******************************************************************************
   dirvec €Î¥á¥â¥ê³ä€êÅö€Æ€ò¹Ô€Š
 *****************************************************************************)


let rec create_dirvec _ =
  let v3 = Array.create 3 0.0 in
  let consts = Array.create n_objects.(0) v3 in
  (v3, consts)
in

let rec create_dirvec_elements d index =
  if index >= 0 then (
    d.(index) <- create_dirvec();
    create_dirvec_elements d (index - 1)
   ) else ()
in

let rec create_dirvecs index =
  if index >= 0 then (
    dirvecs.(index) <- Array.create 120 (create_dirvec());
    create_dirvec_elements dirvecs.(index) 118;
    create_dirvecs (index-1)
   ) else ()
in

(******************************************************************************
   ÊäœõŽØ¿ôÃ£€òžÆ€ÓœÐ€·€Ædirvec€ÎœéŽü²œ€ò¹Ô€Š 
 *****************************************************************************)

let rec init_dirvec_constants vecset index =
  if index >= 0 then (
    setup_dirvec_constants vecset.(index);
    init_dirvec_constants vecset (index - 1)
   ) else ()
in

let rec init_vecset_constants index =
  if index >= 0 then (
    init_dirvec_constants dirvecs.(index) 119;
    init_vecset_constants (index - 1)
   ) else ()
in

let rec init_dirvecs _ =
  create_dirvecs 4;
  calc_dirvec_rows 9 0 0;
  init_vecset_constants 4
in

(******************************************************************************
   Ž°ÁŽ¶ÀÌÌÈ¿ŒÍÀ®Ê¬€ò»ý€ÄÊªÂÎ€ÎÈ¿ŒÍŸðÊó€òœéŽü²œ€¹€ë
 *****************************************************************************)

(* È¿ŒÍÊ¿ÌÌ€òÄÉ²Ã€¹€ë *)
let rec add_reflection index surface_id bright v0 v1 v2 =
  let dvec = create_dirvec() in
  vecset (d_vec dvec) v0 v1 v2; (* È¿ŒÍž÷€Îžþ€­ *)
  setup_dirvec_constants dvec;

  reflections.(index) <- (surface_id, dvec, bright)
in

(* ÄŸÊýÂÎ€Î³ÆÌÌ€Ë€Ä€€€ÆŸðÊó€òÄÉ²Ã€¹€ë *)
let rec setup_rect_reflection obj_id obj =
  let sid = obj_id * 4 in
  let nr = n_reflections.(0) in
  let br = 1.0 -. o_diffuse obj in
  let n0 = fneg light.(0) in
  let n1 = fneg light.(1) in
  let n2 = fneg light.(2) in
  add_reflection nr (sid+1) br light.(0) n1 n2;
  add_reflection (nr+1) (sid+2) br n0 light.(1) n2;
  add_reflection (nr+2) (sid+3) br n0 n1 light.(2);
  n_reflections.(0) <- nr + 3
in

(* Ê¿ÌÌ€Ë€Ä€€€ÆŸðÊó€òÄÉ²Ã€¹€ë *)
let rec setup_surface_reflection obj_id obj =
  let sid = obj_id * 4 + 1 in
  let nr = n_reflections.(0) in
  let br = 1.0 -. o_diffuse obj in
  let p = veciprod light (o_param_abc obj) in

  add_reflection nr sid br
    (2.0 *. o_param_a obj *. p -. light.(0))
    (2.0 *. o_param_b obj *. p -. light.(1))
    (2.0 *. o_param_c obj *. p -. light.(2));
  n_reflections.(0) <- nr + 1
in


(* ³Æ¥ª¥Ö¥ž¥§¥¯¥È€ËÂÐ€·¡¢È¿ŒÍ€¹€ëÊ¿ÌÌ€¬€¢€ì€Ð€œ€ÎŸðÊó€òÄÉ²Ã€¹€ë *)
let rec setup_reflections obj_id = 
  if obj_id >= 0 then
    let obj = objects.(obj_id) in
    if o_reflectiontype obj = 2 then
      if fless (o_diffuse obj) 1.0 then
	let m_shape = o_form obj in
	(* ÄŸÊýÂÎ€ÈÊ¿ÌÌ€Î€ß¥µ¥Ý¡Œ¥È *)
	if m_shape = 1 then 
	  setup_rect_reflection obj_id obj
	else if m_shape = 2 then
	  setup_surface_reflection obj_id obj
	else ()
      else ()
    else ()
  else ()
in

(*****************************************************************************
   ÁŽÂÎ€ÎÀ©žæ
 *****************************************************************************)

(* ¥ì¥€¥È¥ì€Î³Æ¥¹¥Æ¥Ã¥×€ò¹Ô€ŠŽØ¿ô€òœçŒ¡žÆ€ÓœÐ€¹ *)
let rec rt size_x size_y =
(
 image_size.(0) <- size_x;
 image_size.(1) <- size_y;
 image_center.(0) <- size_x / 2;
 image_center.(1) <- size_y / 2;
 scan_pitch.(0) <- 128.0 /. float_of_int size_x;
 let prev = create_pixelline () in
 let cur  = create_pixelline () in
 let next = create_pixelline () in
 read_parameter();
 write_ppm_header ();
 init_dirvecs();
 veccpy (d_vec light_dirvec) light;
 setup_dirvec_constants light_dirvec;
 setup_reflections (n_objects.(0) - 1);
 pretrace_line cur 0 0;
 scan_line 0 prev cur next 2 
)
in

let _ = rt 128 128

in 0
