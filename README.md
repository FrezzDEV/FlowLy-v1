# FlowLy-v1

## Скачать APK

[**Скачать последнюю версию APK**](https://github.com/FrezzDEV/FlowLy-v1/releases/latest/download/app-release.apk)

APK автоматически публикуется в GitHub Releases после запуска release workflow.

## Фоновый музыкальный плеер

Плеер подключён к `audio_service` + `just_audio`: состояние, play/pause, seek, previous/next и stop синхронизируются с системной media session. На Android это даёт медиаконтроллер в панели уведомлений и управление с экрана блокировки; на iOS — системные Now Playing/Lock Screen controls.

Для публикации Android-сборки проект также должен содержать стандартный Flutter `android/` runner с конфигурацией `audio_service`: `WAKE_LOCK`, `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_MEDIA_PLAYBACK`, `AudioService` service и `MediaButtonReceiver`. В текущем репозитории platform runner отсутствует, поэтому Dart-интеграция подготовлена, но сам APK ещё нужно собрать из полноценного Flutter-проекта.
