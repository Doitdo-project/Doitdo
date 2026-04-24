import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 웹 빌드에서 앱을 모바일 디바이스 프레임 안에 렌더링하는 개발용 셸.
///
/// - 실제 앱 UI 는 `widget.child`(= `MaterialApp.router`) 로 주입되며, 셸은
///   상단 툴바(디바이스 선택·Rotate)와 검정 폰 프레임을 앱 바깥쪽에 덧댄다.
/// - 셸 내부에서 `ScreenUtil.configure` 와 커스텀 `MediaQuery` 를 다시 세팅해
///   디자인 기준(375×812) 을 각 디바이스 viewport 에 맞춰 동작시킨다.
/// - `isEnabled` 이 `true` 일 때만 이 셸을 쓴다 — 이 외 (모바일/데스크톱 네이티브
///   및 `/app` 경로 진입) 에서는 평소의 `ScreenUtilInit` 경로로 가야 한다.
///
/// 자체적으로 `Doitdo` prefix 규칙(가이드 §5) 을 따르되, 앱 디자인 시스템
/// (`DoitdoColors`, `DoitdoPrimaryButton` 등) 은 **의도적으로 사용하지 않는다**.
/// 이유: 이 셸은 유저에게 노출되지 않는 개발 도구이고, 앱 테마와 무관하게
/// 자기만의 컨트롤 UI 를 가져야 하기 때문.
class DoitdoWebPreviewShell extends StatefulWidget {
  const DoitdoWebPreviewShell({
    super.key,
    required this.child,
    required this.designSize,
    required this.minTextAdapt,
    required this.splitScreenMode,
  });

  final Widget child;
  final Size designSize;
  final bool minTextAdapt;
  final bool splitScreenMode;

  /// 현재 브라우저 URL 을 보고 프리뷰 모드를 켤지 결정.
  /// - `/preview`, `?preview=1` → 켜짐
  /// - `/app`, `?preview=0|false|off` → 꺼짐
  /// - 특정 스테이징 호스트(`j14d101.p.ssafy.io`) 에서는 기본 켜짐
  /// - 그 외 (localhost 등) 는 꺼짐
  ///
  /// go_router 의 hash URL 모드 때문에 원본 쿼리가 fragment 로 옮겨지는 경우가
  /// 있어 (`?preview=1` → `#/welcome?preview=1`), fragment 안의 쿼리도 함께 본다.
  static bool get isEnabled {
    if (!kIsWeb) return false;

    final uri = Uri.base;
    final pathSegments = uri.pathSegments;

    final queryParams = <String, String>{
      ...uri.queryParameters,
      ..._queryParamsFromFragment(uri.fragment),
    };
    final preview = queryParams['preview'];
    final fragmentPathFirst = _firstPathSegmentOfFragment(uri.fragment);

    // /app 또는 fragment(#/app/...) 로 진입 시 프리뷰 꺼짐.
    if (pathSegments.isNotEmpty && pathSegments.first == 'app') return false;
    if (fragmentPathFirst == 'app') return false;

    // /preview 또는 fragment(#/preview/...) 로 진입 시 프리뷰 켜짐.
    if (pathSegments.isNotEmpty && pathSegments.first == 'preview') return true;
    if (fragmentPathFirst == 'preview') return true;

    if (preview != null) {
      final normalized = preview.toLowerCase();
      return normalized != '0' &&
          normalized != 'false' &&
          normalized != 'off';
    }

    return uri.host == 'j14d101.p.ssafy.io';
  }

  /// fragment(`/welcome?preview=1`) 에서 쿼리 파라미터를 추출.
  /// 물음표가 없으면 빈 맵.
  static Map<String, String> _queryParamsFromFragment(String fragment) {
    final qIndex = fragment.indexOf('?');
    if (qIndex < 0) return const {};
    final raw = fragment.substring(qIndex + 1);
    // 안전하게 파싱하기 위해 가짜 URI 로 감싸서 처리.
    try {
      return Uri.parse('http://x?$raw').queryParameters;
    } catch (_) {
      return const {};
    }
  }

  /// fragment(`/welcome?x=y`) 의 첫 경로 세그먼트 추출. 예: 'welcome'.
  static String? _firstPathSegmentOfFragment(String fragment) {
    var path = fragment;
    final qIndex = path.indexOf('?');
    if (qIndex >= 0) path = path.substring(0, qIndex);
    if (path.startsWith('/')) path = path.substring(1);
    if (path.isEmpty) return null;
    final slashIndex = path.indexOf('/');
    return slashIndex < 0 ? path : path.substring(0, slashIndex);
  }

  @override
  State<DoitdoWebPreviewShell> createState() => _DoitdoWebPreviewShellState();
}

class _DoitdoWebPreviewShellState extends State<DoitdoWebPreviewShell> {
  static const List<_PreviewDevice> _devices = [
    _PreviewDevice(id: 's24', label: 'Galaxy S24', viewport: Size(360, 780)),
    _PreviewDevice(
      id: 's24_ultra',
      label: 'Galaxy S24 Ultra',
      viewport: Size(412, 915),
    ),
    _PreviewDevice(
      id: 'flip6',
      label: 'Galaxy Z Flip6',
      viewport: Size(360, 880),
    ),
    _PreviewDevice(
      id: 'fold6_cover',
      label: 'Galaxy Z Fold6 Cover',
      viewport: Size(344, 844),
    ),
    _PreviewDevice(
      id: 'fold6_open',
      label: 'Galaxy Z Fold6 Open',
      viewport: Size(904, 1053),
    ),
  ];

  _PreviewDevice _selectedDevice = _devices.first;
  bool _isLandscape = false;

  @override
  void initState() {
    super.initState();
    // `isEnabled` 와 동일한 규칙으로 fragment 쿼리까지 포함해 읽는다.
    final params = <String, String>{
      ...Uri.base.queryParameters,
      ...DoitdoWebPreviewShell._queryParamsFromFragment(Uri.base.fragment),
    };
    final requestedDeviceId = params['device'];
    _selectedDevice = _devices.firstWhere(
      (device) => device.id == requestedDeviceId,
      orElse: () => _devices.first,
    );
    final landscape = params['landscape']?.toLowerCase();
    _isLandscape = landscape == '1' || landscape == 'true';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final viewportSize = _isLandscape
        ? Size(_selectedDevice.viewport.height, _selectedDevice.viewport.width)
        : _selectedDevice.viewport;
    final frameSize = Size(viewportSize.width + 28, viewportSize.height + 28);
    final safePadding = _isLandscape
        ? const EdgeInsets.symmetric(horizontal: 20)
        : const EdgeInsets.only(top: 28, bottom: 12);

    // 프리뷰 툴바(Text / ChoiceChip / FilledButton) 는 Directionality / Theme /
    // MaterialLocalizations / Material ancestor 를 요구한다. 개별 주입보다 별개의
    // MaterialApp 루트를 만들어 일괄 제공하는 편이 안정적.
    // 내부 widget.child 는 자기만의 MaterialApp.router 를 들고 있어 중첩돼도
    // 외곽 MaterialApp 이 실제 앱 라우팅에는 관여하지 않는다.
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(useMaterial3: true),
      home: ColoredBox(
        color: const Color(0xFFF1EEE7),
        child: SafeArea(
          minimum: const EdgeInsets.all(20),
          child: Column(
            children: [
              _PreviewToolbar(
                devices: _devices,
                selectedDevice: _selectedDevice,
                isLandscape: _isLandscape,
                onDeviceSelected: (device) {
                  setState(() => _selectedDevice = device);
                },
                onRotatePressed: () {
                  setState(() => _isLandscape = !_isLandscape);
                },
              ),
              const SizedBox(height: 20),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final previewHeight = math.max(
                      0.0,
                      constraints.maxHeight - 8,
                    );
                    return Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: constraints.maxWidth,
                          maxHeight: previewHeight,
                        ),
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _PreviewHeader(
                                label: _selectedDevice.label,
                                viewportSize: viewportSize,
                                isLandscape: _isLandscape,
                              ),
                              const SizedBox(height: 14),
                              Container(
                                width: frameSize.width,
                                height: frameSize.height,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1D2127),
                                  borderRadius: BorderRadius.circular(42),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x33111A23),
                                      blurRadius: 48,
                                      offset: Offset(0, 28),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(30),
                                  child: Container(
                                    color: theme.scaffoldBackgroundColor,
                                    child: _PreviewViewport(
                                      designSize: widget.designSize,
                                      minTextAdapt: widget.minTextAdapt,
                                      splitScreenMode: widget.splitScreenMode,
                                      viewportSize: viewportSize,
                                      safePadding: safePadding,
                                      previewKey: ValueKey(
                                        '${_selectedDevice.id}:${_isLandscape ? 'landscape' : 'portrait'}',
                                      ),
                                      mediaQuery: mediaQuery,
                                      child: widget.child,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewViewport extends StatelessWidget {
  const _PreviewViewport({
    required this.designSize,
    required this.minTextAdapt,
    required this.splitScreenMode,
    required this.viewportSize,
    required this.safePadding,
    required this.previewKey,
    required this.mediaQuery,
    required this.child,
  });

  final Size designSize;
  final bool minTextAdapt;
  final bool splitScreenMode;
  final Size viewportSize;
  final EdgeInsets safePadding;
  final Key previewKey;
  final MediaQueryData mediaQuery;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final previewMediaQuery = mediaQuery.copyWith(
      size: viewportSize,
      padding: safePadding,
      viewPadding: safePadding,
      viewInsets: EdgeInsets.zero,
    );

    ScreenUtil.configure(
      data: previewMediaQuery,
      designSize: designSize,
      splitScreenMode: splitScreenMode,
      minTextAdapt: minTextAdapt,
    );

    return MediaQuery(
      data: previewMediaQuery,
      child: SizedBox(
        width: viewportSize.width,
        height: viewportSize.height,
        child: KeyedSubtree(key: previewKey, child: child),
      ),
    );
  }
}

class _PreviewToolbar extends StatelessWidget {
  const _PreviewToolbar({
    required this.devices,
    required this.selectedDevice,
    required this.isLandscape,
    required this.onDeviceSelected,
    required this.onRotatePressed,
  });

  final List<_PreviewDevice> devices;
  final _PreviewDevice selectedDevice;
  final bool isLandscape;
  final ValueChanged<_PreviewDevice> onDeviceSelected;
  final VoidCallback onRotatePressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.9),
      elevation: 0,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const _PreviewBadge(label: 'Preview Mode'),
            for (final device in devices)
              ChoiceChip(
                label: Text(device.label),
                selected: device.id == selectedDevice.id,
                onSelected: (_) => onDeviceSelected(device),
              ),
            FilledButton.tonalIcon(
              onPressed: onRotatePressed,
              icon: Icon(
                isLandscape
                    ? Icons.stay_current_portrait
                    : Icons.screen_rotation,
              ),
              label: Text(isLandscape ? 'Portrait' : 'Landscape'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewHeader extends StatelessWidget {
  const _PreviewHeader({
    required this.label,
    required this.viewportSize,
    required this.isLandscape,
  });

  final String label;
  final Size viewportSize;
  final bool isLandscape;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sizeLabel =
        '${viewportSize.width.toInt()} x ${viewportSize.height.toInt()}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            sizeLabel,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF667085),
            ),
          ),
          const SizedBox(width: 12),
          _PreviewBadge(label: isLandscape ? 'Landscape' : 'Portrait'),
        ],
      ),
    );
  }
}

class _PreviewBadge extends StatelessWidget {
  const _PreviewBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF18212D),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PreviewDevice {
  const _PreviewDevice({
    required this.id,
    required this.label,
    required this.viewport,
  });

  final String id;
  final String label;
  final Size viewport;
}
