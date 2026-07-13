{{flutter_js}}
{{flutter_build_config}}

// canvaskit을 CDN(gstatic)이 아닌 앱에 번들된 로컬 경로에서 로드한다.
// (오프라인/프록시 환경에서도 웹 미리보기가 동작하도록)
_flutter.loader.load({
  config: {
    canvasKitBaseUrl: "canvaskit/",
  },
});
