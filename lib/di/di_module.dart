import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

@module
abstract class InjectorModule {
  @lazySingleton
  AssetsAudioPlayer get audioPlayer => AssetsAudioPlayer();

  @lazySingleton
  FirebaseFirestore get firestore => FirebaseFirestore.instance;
}
