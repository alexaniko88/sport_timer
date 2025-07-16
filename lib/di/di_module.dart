import 'package:audioplayers/audioplayers.dart';
import 'package:injectable/injectable.dart';

@module
abstract class InjectorModule {
  @lazySingleton
  AudioPlayer get audioPlayer => AudioPlayer();
}
