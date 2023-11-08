{File generated via oxbuildglextdscr.}

   oglnExtensionDescriptors = 55;

{ extension IDs }
   cGL_ARB_depth_texture = 0;
   cGL_ARB_fragment_program = 1;
   cGL_ARB_multitexture = 2;
   cGL_ARB_point_parameters = 3;
   cGL_ARB_shadow = 4;
   cGL_ARB_texture_border_clamp = 5;
   cGL_ARB_texture_compression = 6;
   cGL_ARB_texture_cube_map = 7;
   cGL_ARB_texture_env_add = 8;
   cGL_ARB_texture_env_combine = 9;
   cGL_ARB_texture_env_dot3 = 10;
   cGL_ARB_texture_env_crossbar = 11;
   cGL_ARB_transpose_matrix = 12;
   cGL_ARB_vertex_buffer_object = 13;
   cGL_ARB_vertex_program = 14;
   cGL_ARB_window_pos = 15;
   cGL_EXT_abgr = 16;
   cGL_EXT_bgra = 17;
   cGL_EXT_blend_color = 18;
   cGL_EXT_blend_func_separate = 19;
   cGL_EXT_blend_minmax = 20;
   cGL_EXT_blend_subtract = 21;
   cGL_EXT_clip_volume_hint = 22;
   cGL_EXT_compiled_vertex_array = 23;
   cGL_EXT_cull_vertex = 24;
   cGL_EXT_draw_range_elements = 25;
   cGL_EXT_fog_coord = 26;
   cGL_EXT_multi_draw_arrays = 27;
   cGL_EXT_packed_pixels = 28;
   cGL_EXT_rescale_normal = 29;
   cGL_EXT_secondary_color = 30;
   cGL_EXT_separate_specular_color = 31;
   cGL_EXT_shadow_funcs = 32;
   cGL_EXT_stencil_two_side = 33;
   cGL_EXT_stencil_wrap = 34;
   cGL_EXT_texture_compression_s3tc = 35;
   cGL_EXT_texture_env_add = 36;
   cGL_EXT_texture_env_combine = 37;
   cGL_EXT_texture_lod_bias = 38;
   cGL_EXT_texture_filter_anisotropic = 39;
   cGL_EXT_texture3D = 40;
   cGL_3DFX_texture_compression_FXT1 = 41;
   cGL_IBM_texture_mirrored_repeat = 42;
   cGL_NV_blend_square = 43;
   cGL_NV_texgen_reflection = 44;
   cGL_SGIS_generate_mipmap = 45;
   cGL_SGIS_texture_edge_clamp = 46;
   cGL_SGIS_texture_lod = 47;
   cGL_WIN_swap_hint = 48;
   cGL_ARB_vertex_shader = 49;
   cGL_ARB_fragment_shader = 50;
   cGL_ARB_shader_objects = 51;
   cGL_ARB_shading_language_100 = 52;
   cGL_ARB_compatibility = 53;
   cGL_ARB_debug_output = 54;

TYPE
   oglTExtensionDescriptors = array[0 .. oglnExtensionDescriptors - 1] of oglTExtensionDescriptor;

CONST

{ extension descriptors }
   oglcExtensionDescriptors: oglTExtensionDescriptors = (
      (Name: 'GL_ARB_depth_texture'; Present: false),
      (Name: 'GL_ARB_fragment_program'; Present: false),
      (Name: 'GL_ARB_multitexture'; Present: false),
      (Name: 'GL_ARB_point_parameters'; Present: false),
      (Name: 'GL_ARB_shadow'; Present: false),
      (Name: 'GL_ARB_texture_border_clamp'; Present: false),
      (Name: 'GL_ARB_texture_compression'; Present: false),
      (Name: 'GL_ARB_texture_cube_map'; Present: false),
      (Name: 'GL_ARB_texture_env_add'; Present: false),
      (Name: 'GL_ARB_texture_env_combine'; Present: false),
      (Name: 'GL_ARB_texture_env_dot3'; Present: false),
      (Name: 'GL_ARB_texture_env_crossbar'; Present: false),
      (Name: 'GL_ARB_transpose_matrix'; Present: false),
      (Name: 'GL_ARB_vertex_buffer_object'; Present: false),
      (Name: 'GL_ARB_vertex_program'; Present: false),
      (Name: 'GL_ARB_window_pos'; Present: false),
      (Name: 'GL_EXT_abgr'; Present: false),
      (Name: 'GL_EXT_bgra'; Present: false),
      (Name: 'GL_EXT_blend_color'; Present: false),
      (Name: 'GL_EXT_blend_func_separate'; Present: false),
      (Name: 'GL_EXT_blend_minmax'; Present: false),
      (Name: 'GL_EXT_blend_subtract'; Present: false),
      (Name: 'GL_EXT_clip_volume_hint'; Present: false),
      (Name: 'GL_EXT_compiled_vertex_array'; Present: false),
      (Name: 'GL_EXT_cull_vertex'; Present: false),
      (Name: 'GL_EXT_draw_range_elements'; Present: false),
      (Name: 'GL_EXT_fog_coord'; Present: false),
      (Name: 'GL_EXT_multi_draw_arrays'; Present: false),
      (Name: 'GL_EXT_packed_pixels'; Present: false),
      (Name: 'GL_EXT_rescale_normal'; Present: false),
      (Name: 'GL_EXT_secondary_color'; Present: false),
      (Name: 'GL_EXT_separate_specular_color'; Present: false),
      (Name: 'GL_EXT_shadow_funcs'; Present: false),
      (Name: 'GL_EXT_stencil_two_side'; Present: false),
      (Name: 'GL_EXT_stencil_wrap'; Present: false),
      (Name: 'GL_EXT_texture_compression_s3tc'; Present: false),
      (Name: 'GL_EXT_texture_env_add'; Present: false),
      (Name: 'GL_EXT_texture_env_combine'; Present: false),
      (Name: 'GL_EXT_texture_lod_bias'; Present: false),
      (Name: 'GL_EXT_texture_filter_anisotropic'; Present: false),
      (Name: 'GL_EXT_texture3D'; Present: false),
      (Name: 'GL_3DFX_texture_compression_FXT1'; Present: false),
      (Name: 'GL_IBM_texture_mirrored_repeat'; Present: false),
      (Name: 'GL_NV_blend_square'; Present: false),
      (Name: 'GL_NV_texgen_reflection'; Present: false),
      (Name: 'GL_SGIS_generate_mipmap'; Present: false),
      (Name: 'GL_SGIS_texture_edge_clamp'; Present: false),
      (Name: 'GL_SGIS_texture_lod'; Present: false),
      (Name: 'GL_WIN_swap_hint'; Present: false),
      (Name: 'GL_ARB_vertex_shader'; Present: false),
      (Name: 'GL_ARB_fragment_shader'; Present: false),
      (Name: 'GL_ARB_shader_objects'; Present: false),
      (Name: 'GL_ARB_shading_language_100'; Present: false),
      (Name: 'GL_ARB_compatibility'; Present: false),
      (Name: 'GL_ARB_debug_output'; Present: false)
   );
