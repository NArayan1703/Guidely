import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'app/bootstrap.dart';
part 'features/auth/auth_screens.dart';
part 'features/tourist/tourist_screens.dart';
part 'features/tourist/more_screens.dart';
part 'features/admin/admin_home.dart';
part 'features/guide/guide_home.dart';
part 'shared/widgets/common_widgets.dart';

const _primary = Color(0xFF146B63);
const _accent = Color(0xFFE66F3A);
const _ink = Color(0xFF1C2927);
const _muted = Color(0xFF667370);
const _surface = Color(0xFFFFFBF6);
bool _supabaseReady = false;
