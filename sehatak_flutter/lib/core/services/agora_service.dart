import 'package:agora_rtc_engine/agora_rtc_engine.dart';

class AgoraService {
  static const String appId = 'a24c7e1ed2f04770ad21281e11915b65';
  static const String appCertificate = 'dc65ae20000547db9a16af15dae43461';
  
  RtcEngine? _engine;
  
  Future<void> initialize() async {
    _engine = createAgoraRtcEngine();
    await _engine!.initialize(const RtcEngineContext(appId: appId));
    await _engine!.enableAudio();
    await _engine!.enableVideo();
  }
  
  Future<void> joinChannel(String channelName, {bool isBroadcaster = true}) async {
    await _engine?.joinChannel(
      token: '',
      channelId: channelName,
      uid: 0,
      options: ChannelMediaOptions(
        clientRoleType: isBroadcaster ? ClientRoleType.clientRoleBroadcaster : ClientRoleType.clientRoleAudience,
      ),
    );
  }
  
  Future<void> leaveChannel() async {
    await _engine?.leaveChannel();
  }
  
  void dispose() {
    _engine?.release();
  }
  
  RtcEngine? get engine => _engine;
}
