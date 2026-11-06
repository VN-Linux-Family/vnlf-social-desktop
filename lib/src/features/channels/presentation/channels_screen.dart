import 'package:flutter/material.dart';

import 'live_channels_screen.dart';

class ChannelsScreen extends StatelessWidget {
  const ChannelsScreen({super.key, this.channelSlug});
  final String? channelSlug;
  @override
  Widget build(BuildContext context) =>
      LiveChannelsScreen(channelSlug: channelSlug);
}
