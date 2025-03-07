import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:spotube/components/Player/PlayerActions.dart';
import 'package:spotube/components/Player/PlayerControls.dart';
import 'package:spotube/components/Shared/PageWindowTitleBar.dart';
import 'package:spotube/components/Shared/SpotubeMarqueeText.dart';
import 'package:spotube/components/Shared/UniversalImage.dart';
import 'package:spotube/hooks/useBreakpoints.dart';
import 'package:spotube/hooks/useCustomStatusBarColor.dart';
import 'package:spotube/hooks/usePaletteColor.dart';
import 'package:spotube/provider/Playback.dart';
import 'package:spotube/utils/type_conversion_utils.dart';

class PlayerView extends HookConsumerWidget {
  const PlayerView({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, ref) {
    final currentTrack = ref.watch(playbackProvider.select(
      (value) => value.track,
    ));
    final breakpoint = useBreakpoints();

    useEffect(() {
      if (breakpoint.isMoreThan(Breakpoints.md)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          GoRouter.of(context).pop();
        });
      }
      return null;
    }, [breakpoint]);

    String albumArt = useMemoized(
      () => TypeConversionUtils.image_X_UrlString(
        currentTrack?.album?.images,
        index: (currentTrack?.album?.images?.length ?? 1) - 1,
        placeholder: ImagePlaceholder.albumArt,
      ),
      [currentTrack?.album?.images],
    );

    final PaletteColor paletteColor = usePaletteColor(albumArt, ref);

    useCustomStatusBarColor(
      paletteColor.color,
      GoRouter.of(context).location == "/player",
      noSetBGColor: true,
    );

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: UniversalImage.imageProvider(albumArt),
            fit: BoxFit.cover,
          ),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Material(
            color: paletteColor.color.withOpacity(.5),
            child: SafeArea(
              child: Column(
                children: [
                  PageWindowTitleBar(
                    leading: const BackButton(),
                    backgroundColor: Colors.transparent,
                    foregroundColor: paletteColor.titleTextColor,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 30,
                          child: SpotubeMarqueeText(
                            text: currentTrack?.name ?? "Not playing",
                            style:
                                Theme.of(context).textTheme.headline5?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: paletteColor.titleTextColor,
                                    ),
                            isHovering: true,
                          ),
                        ),
                        TypeConversionUtils.artists_X_ClickableArtists(
                          currentTrack?.artists ?? [],
                          textStyle:
                              Theme.of(context).textTheme.headline6!.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: paletteColor.bodyTextColor,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  HookBuilder(builder: (context) {
                    final ticker = useSingleTickerProvider();
                    final controller = useAnimationController(
                      duration: const Duration(seconds: 10),
                      vsync: ticker,
                    )..repeat();
                    return RotationTransition(
                      turns: Tween(begin: 0.0, end: 1.0).animate(controller),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: paletteColor.titleTextColor,
                            width: 2,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
                          backgroundImage:
                              UniversalImage.imageProvider(albumArt),
                          radius: MediaQuery.of(context).size.width *
                              (breakpoint.isSm ? 0.4 : 0.3),
                        ),
                      ),
                    );
                  }),
                  const Spacer(),
                  PlayerActions(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    floatingQueue: false,
                  ),
                  PlayerControls(iconColor: paletteColor.bodyTextColor),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
